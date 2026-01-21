class ClaudeRecipeService
  def initialize(recipe)
    @recipe = recipe
  end

  def generate
    client = Anthropic::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])

    response = client.messages.create(
      model: 'claude-sonnet-4-20250514',
      max_tokens: 2000,
      messages: [
        {
          role: 'user',
          content: build_prompt
        }
      ]
    )

    response.content.first.text
  rescue Anthropic::AuthenticationError => e
    Rails.logger.error("Erreur authentification Claude: #{e.message}")
    nil
  rescue Anthropic::RateLimitError => e
    Rails.logger.error("Limite de taux API Claude: #{e.message}")
    nil
  rescue Anthropic::InvalidRequestError => e
    Rails.logger.error("Requête invalide Claude: #{e.message}")
    nil
  rescue StandardError => e
    Rails.logger.error("Erreur inattendue: #{e.class} - #{e.message}")
    nil
  end

  private

  def build_prompt
    <<~PROMPT
      Tu es un chef cuisinier expert français. Génère une recette détaillée et créative avec ces critères:

      - Type de plat: #{@recipe.choice}
      - Nombre de convives: #{@recipe.guests}
      - Régime alimentaire: #{@recipe.diet}
      - Type de cuisine: #{@recipe.cuisine}
      - Temps total disponible: #{@recipe.duration}
      - Niveau de difficulté: #{@recipe.difficulty}
      - Équipements disponibles: #{@recipe.equipments_text}
      - Ingrédients souhaités à inclure obligatoirement: #{@recipe.ingredients_text}
      - Ingrédients INTERDITS (ne JAMAIS utiliser): #{@recipe.excluded_ingredients_text}

      #{contrainte_ingredients}

      #{contrainte_exclusions}

      #{contrainte_repas_froid}

      #{contrainte_healthy}

      #{contrainte_enfant}

      #{contrainte_orientale}

      #{contrainte_asiatique}

      #{contrainte_equipements}

      Réponds en français avec ce format exact (utilise le format Markdown):

      ## [Nom de la recette]

      **Temps de préparation:** [X minutes]
      **Temps de cuisson:** [X minutes]
      **Difficulté:** #{@recipe.difficulty}

      ### Ingrédients (pour #{@recipe.guests} personne#{'s' if @recipe.guests > 1})

      - [Ingrédient]: [quantité précise en grammes ou unités]
      - ...

      ### Préparation

      1. [Étape détaillée avec temps et température si applicable]
      2. [Étape suivante]
      3. ...

      ### Conseils du chef

      - [2-3 conseils pratiques pour réussir la recette]
    PROMPT
  end

  def contrainte_ingredients
    user_ingredients_count = @recipe.ingredients.count

    case @recipe.duration
    when 'Express (<15mn)'
      max_total = 4
      remaining = [max_total - user_ingredients_count, 0].max
      <<~CONTRAINTE
        **CONTRAINTE IMPORTANTE - RECETTE EXPRESS:**
        La recette doit utiliser EXACTEMENT #{max_total} ingrédients au total (hors sel, poivre, huile).
        L'utilisateur a déjà spécifié #{user_ingredients_count} ingrédient(s) que tu DOIS inclure.
        Tu peux donc ajouter au maximum #{remaining} ingrédient(s) supplémentaire(s).
        Ceci est une contrainte STRICTE pour une recette rapide.
      CONTRAINTE
    when 'Rapide (15-30mn)'
      max_total = 5
      remaining = [max_total - user_ingredients_count, 0].max
      <<~CONTRAINTE
        **CONTRAINTE IMPORTANTE - RECETTE RAPIDE:**
        La recette doit utiliser EXACTEMENT #{max_total} ingrédients au total (hors sel, poivre, huile).
        L'utilisateur a déjà spécifié #{user_ingredients_count} ingrédient(s) que tu DOIS inclure.
        Tu peux donc ajouter au maximum #{remaining} ingrédient(s) supplémentaire(s).
        Ceci est une contrainte STRICTE pour une recette rapide.
      CONTRAINTE
    else
      # Pas de contrainte pour Classique et Élaboré
      ""
    end
  end

  def contrainte_exclusions
    return "" if @recipe.excluded_ingredients.empty?

    <<~CONTRAINTE
      **CONTRAINTE STRICTE - INGRÉDIENTS INTERDITS:**
      Les ingrédients suivants sont ABSOLUMENT INTERDITS et ne doivent JAMAIS apparaître dans la recette: #{@recipe.excluded_ingredients_text}.
      Cela inclut ces ingrédients sous toutes leurs formes (frais, surgelés, en conserve, en poudre, etc.).
    CONTRAINTE
  end

  def contrainte_repas_froid
    return "" unless @recipe.equipments&.include?('Sans')

    <<~CONTRAINTE
      **CONTRAINTE STRICTE - REPAS FROID:**
      L'utilisateur n'a PAS d'équipement de cuisson disponible. Tu DOIS proposer une recette FROIDE qui ne nécessite AUCUNE cuisson.
      Pas de plaques de cuisson, pas de four, pas d'airfryer, pas de thermomix.
      La recette doit pouvoir être préparée entièrement à froid (salades, tartares, carpaccios, verrines froides, sandwichs élaborés, etc.).
    CONTRAINTE
  end

  def contrainte_healthy
    return "" unless @recipe.diet == 'Healthy'

    <<~CONTRAINTE
      **CONTRAINTE STRICTE - RÉGIME HEALTHY:**
      La recette doit être équilibrée et saine, MAIS rester gourmande et savoureuse. Tu DOIS respecter ces règles:
      - Privilégier les légumes frais et de saison
      - Utiliser des protéines maigres (poulet, poisson, légumineuses, tofu)
      - Éviter les sucres ajoutés et les graisses saturées
      - Préférer les céréales complètes aux céréales raffinées
      - Limiter le sel et utiliser des herbes et épices pour assaisonner
      - Favoriser les cuissons douces (vapeur, four, poêle avec peu de matière grasse)
      - IMPORTANT: Malgré ces contraintes, la recette doit rester gourmande et goûteuse. Utilise des associations de saveurs, des épices, des herbes fraîches et des techniques de cuisson qui rehaussent le goût.
    CONTRAINTE
  end

  def contrainte_enfant
    return "" unless @recipe.diet == 'Enfant'

    <<~CONTRAINTE
      **CONTRAINTE STRICTE - RECETTE POUR ENFANT (#{@recipe.age_range}):**
      Cette recette est destinée à un enfant de #{@recipe.age_range}. Tu DOIS absolument respecter ces règles:

      ALIMENTS STRICTEMENT INTERDITS:
      - Abats (foie, rognons, etc.)
      - Piments, épices fortes ou piquantes
      - Tout ingrédient à base d'alcool (vin, bière, liqueur, même pour déglacer)
      - Fruits de mer crus
      - Viandes crues ou peu cuites
      - Fromages au lait cru
      - Miel (pour les moins de 3 ans)

      RÈGLES OBLIGATOIRES:
      - Quantités adaptées à l'âge: portions plus petites qu'un adulte
      - Textures adaptées à l'âge (plus tendres pour les 2-5 ans)
      - Saveurs douces et peu salées
      - Peu ou pas de sauce (sauf sauce tomate nature)
      - Présentation ludique et colorée pour donner envie à l'enfant
      - Aliments faciles à mâcher et à digérer

      IMPORTANT: La recette doit rester appétissante et gourmande pour plaire aux enfants.
    CONTRAINTE
  end

  def contrainte_asiatique
    return "" unless @recipe.cuisine == 'Asiatique'

    <<~CONTRAINTE
      **CONTRAINTE - CUISINE ASIATIQUE:**
      Exclure les recettes indiennes. Se concentrer sur les cuisines d'Asie de l'Est et du Sud-Est (Chine, Japon, Thaïlande, Vietnam, Corée, etc.).
    CONTRAINTE
  end

  def contrainte_orientale
    return "" unless @recipe.cuisine == 'Orientale'

    <<~CONTRAINTE
      **CONTRAINTE STRICTE - CUISINE ORIENTALE (HALAL):**
      Il s'agit de cuisine d'Afrique du Nord et du Moyen-Orient (Israël non inclus).
      Cette recette doit respecter les règles alimentaires halal. Tu DOIS absolument respecter ces règles:

      VIANDES STRICTEMENT INTERDITES:
      - Porc et tous ses dérivés (jambon, lardons, bacon, saucisse de porc, etc.)
      - Charcuterie à base de porc
      - Gélatine de porc

      RÈGLES OBLIGATOIRES:
      - Utiliser uniquement de la viande halal (agneau, bœuf, poulet, dinde)
      - IMPORTANT: Si la recette contient de la viande, tu DOIS écrire "viande halal" dans la liste des ingrédients (ex: "Poulet halal", "Bœuf haché halal", "Agneau halal")
      - Privilégier les épices orientales (cumin, coriandre, cannelle, ras el hanout, curcuma)
      - Proposer des saveurs authentiques de la cuisine orientale (Maghreb, Moyen-Orient)
    CONTRAINTE
  end

  def contrainte_equipements
    contraintes = []

    if @recipe.equipments&.include?('Four')
      contraintes << <<~FOUR
        - **FOUR:** Tu DOIS préciser si un préchauffage est nécessaire (et à quelle température), la température de cuisson exacte en degrés Celsius, et la durée de cuisson précise.
      FOUR
    end

    if @recipe.equipments&.include?('AirFryer')
      contraintes << <<~AIRFRYER
        - **AIRFRYER:** Tu DOIS préciser la température exacte en degrés Celsius et la durée de cuisson précise.
      AIRFRYER
    end

    if @recipe.equipments&.include?('Thermomix')
      contraintes << <<~THERMOMIX
        - **THERMOMIX:** Tu DOIS préciser la vitesse (1 à 10 ou turbo), la température exacte, et le temps de cuisson pour chaque étape utilisant le Thermomix.
      THERMOMIX
    end

    return "" if contraintes.empty?

    <<~CONTRAINTE
      **INSTRUCTIONS SPÉCIFIQUES POUR LES ÉQUIPEMENTS:**
      #{contraintes.join}
    CONTRAINTE
  end
end
