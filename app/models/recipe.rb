class Recipe
  include ActiveModel::Model
  include ActiveModel::Attributes

  CHOICES = ['Entrée', 'Plat principal', 'Dessert'].freeze
  GUESTS_OPTIONS = (1..6).to_a.freeze
  DIETS = ['Sans restriction', 'Sans gluten', 'Diabétique', 'Végétarien', 'Healthy', 'Enfant'].freeze
  AGE_RANGES = ['2 à 5 ans', '6 à 8 ans', '8 à 10 ans'].freeze
  CUISINES = ['Française', 'Italienne', 'Espagnole', 'Sud-américaine', 'Asiatique', 'Indienne', 'Orientale'].freeze
  DURATIONS = ['Express (<15mn)', 'Rapide (15-30mn)', 'Classique (30-60mn)', 'Élaboré (>60mn)'].freeze
  DIFFICULTIES = ['Facile', 'Moyen', 'Gastronomique'].freeze
  EQUIPMENTS = ['Sans','Plaques de cuisson', 'Four', 'AirFryer', 'Thermomix'].freeze

  attribute :choice, :string
  attribute :guests, :integer
  attribute :diet, :string
  attribute :age_range, :string
  attribute :cuisine, :string
  attribute :duration, :string
  attribute :difficulty, :string
  attribute :ingredient1, :string
  attribute :ingredient2, :string
  attribute :ingredient3, :string
  attribute :ingredient4, :string
  attribute :excluded1, :string
  attribute :excluded2, :string
  attribute :excluded3, :string
  attribute :excluded4, :string
  attribute :response, :string

  # Equipments est un tableau
  attr_accessor :equipments

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

  def initialize(attributes = {})
    super
    @equipments ||= []
    # Nettoyer les valeurs vides du tableau
    @equipments = @equipments.reject(&:blank?) if @equipments.is_a?(Array)
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
