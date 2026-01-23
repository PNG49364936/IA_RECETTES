class Recipe < ApplicationRecord
  belongs_to :user

  CHOICES = ['Entrée', 'Plat principal', 'Dessert'].freeze
  GUESTS_OPTIONS = (1..6).to_a.freeze
  DIETS = ['Sans restriction', 'Sans gluten', 'Diabétique', 'Végétarien', 'Healthy', 'Enfant'].freeze
  AGE_RANGES = ['2 à 5 ans', '6 à 8 ans', '8 à 10 ans'].freeze
  CUISINES = ['Française', 'Italienne', 'Espagnole', 'Sud-américaine', 'Asiatique', 'Indienne', 'Orientale'].freeze
  DURATIONS = ['Express (<15mn)', 'Rapide (15-30mn)', 'Classique (30-60mn)', 'Élaboré (>60mn)'].freeze
  DIFFICULTIES = ['Facile', 'Moyen', 'Gastronomique'].freeze
  EQUIPMENTS = ['Sans','Plaques de cuisson', 'Four', 'AirFryer', 'Thermomix'].freeze

  serialize :equipments, coder: JSON

  validates :title, uniqueness: { scope: :user_id, message: "Recette déjà sauvegardée" }, allow_blank: true

  validate :validate_all_fields
  validate :at_least_one_equipment
  validate :gastronomique_not_express
  validate :age_range_required_for_enfant

  FIELD_LABELS = {
    choice: "Type de plat",
    guests: "Nombre de convives",
    diet: "Régime alimentaire",
    age_range: "Tranche d'âge",
    cuisine: "Type de cuisine",
    duration: "Temps de préparation",
    difficulty: "Niveau de difficulté",
    equipments: "Équipement de cuisson"
  }.freeze

  def validate_all_fields
    validate_field(:choice, CHOICES)
    validate_field(:guests, GUESTS_OPTIONS)
    validate_field(:diet, DIETS)
    validate_field(:cuisine, CUISINES)
    validate_field(:duration, DURATIONS)
    validate_field(:difficulty, DIFFICULTIES)
  end

  def validate_field(field, valid_options)
    value = send(field)
    label = FIELD_LABELS[field]

    if value.blank?
      errors.add(:base, "#{label} → doit être renseigné")
    elsif !valid_options.include?(value)
      errors.add(:base, "#{label} → sélection invalide")
    end
  end

  def equipments
    value = super
    return [] if value.blank?
    value.is_a?(Array) ? value : []
  end

  def equipments=(value)
    cleaned = value.is_a?(Array) ? value.reject(&:blank?) : []
    super(cleaned)
  end

  def ingredients
    [ingredient1, ingredient2, ingredient3, ingredient4].compact_blank
  end

  def ingredients_filtered
    if cuisine == 'Orientale'
      ingredients.reject { |i| i.downcase.include?('porc') }
    else
      ingredients
    end
  end

  def ingredients_text
    ingredients_filtered.any? ? ingredients_filtered.join(', ') : 'Aucun ingrédient spécifié'
  end

  def has_porc_with_orientale?
    cuisine == 'Orientale' && ingredients.any? { |i| i.downcase.include?('porc') }
  end

  def excluded_ingredients
    [excluded1, excluded2, excluded3, excluded4].compact_blank
  end

  def excluded_ingredients_text
    excluded_ingredients.any? ? excluded_ingredients.join(', ') : 'Aucun'
  end

  def equipments_text
    equipments.any? ? equipments.join(', ') : 'Aucun équipement spécifié'
  end

  # Extraire le titre de la recette depuis le contenu Markdown
  def extract_title_from_content
    return "Recette sans titre" if content.blank?

    # Méthode 1: Chercher ## Titre
    lines = content.split("\n")
    lines.each do |line|
      if line.strip.start_with?("## ")
        return line.strip.sub(/^##\s*/, '').strip
      end
    end

    # Méthode 2: Prendre le texte avant "**Temps" ou "Temps de préparation"
    if content.include?("**Temps")
      titre = content.split("**Temps").first.strip
      return titre if titre.present? && titre.length < 100
    end

    # Méthode 3: Première ligne non vide (limitée à 80 caractères)
    first_line = lines.find { |l| l.strip.present? }&.strip
    if first_line
      return first_line.length > 80 ? "#{first_line[0..77]}..." : first_line
    end

    "Recette sans titre"
  end

  private

  def at_least_one_equipment
    if equipments.blank? || equipments.reject(&:blank?).empty?
      errors.add(:base, "#{FIELD_LABELS[:equipments]} → doit être renseigné")
    end
  end

  def gastronomique_not_express
    if difficulty == 'Gastronomique' && duration == 'Express (<15mn)'
      errors.add(:base, "#{FIELD_LABELS[:duration]} → incompatible avec le niveau Gastronomique (minimum 16 minutes)")
    end
  end

  def age_range_required_for_enfant
    if diet == 'Enfant'
      if age_range.blank?
        errors.add(:base, "#{FIELD_LABELS[:age_range]} → doit être renseignée pour le régime Enfant")
      elsif !AGE_RANGES.include?(age_range)
        errors.add(:base, "#{FIELD_LABELS[:age_range]} → sélection invalide")
      end
    end
  end
end
