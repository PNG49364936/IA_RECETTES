class ClaudeRecipeService
  def initialize(recipe, locale: :fr)
    @recipe = recipe
    @locale = locale.to_sym
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

  def spanish?
    @locale == :es
  end

  def build_prompt
    if spanish?
      build_prompt_es
    else
      build_prompt_fr
    end
  end

  def build_prompt_fr
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

      #{contrainte_ingredients_fr}

      #{contrainte_exclusions_fr}

      #{contrainte_repas_froid_fr}

      #{contrainte_healthy_fr}

      #{contrainte_enfant_fr}

      #{contrainte_orientale_fr}

      #{contrainte_asiatique_fr}

      #{contrainte_sans_preference_fr}

      #{contrainte_fusion_fr}

      #{contrainte_usa_fr}

      #{contrainte_equipements_fr}

      Réponds en français avec ce format exact (utilise le format Markdown):

      ## [Nom de la recette]

      **Temps de préparation:** [X minutes]
      **Temps de cuisson:** [X minutes]
      **Difficulté:** #{@recipe.difficulty}
      **Calories:** [X kcal par personne]

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

  def build_prompt_es
    <<~PROMPT
      Eres un chef de cocina experto. Genera una receta detallada y creativa con estos criterios:

      - Tipo de plato: #{translate_choice_es}
      - Número de comensales: #{@recipe.guests}
      - Régimen alimentario: #{translate_diet_es}
      - Tipo de cocina: #{translate_cuisine_es}
      - Tiempo total disponible: #{translate_duration_es}
      - Nivel de dificultad: #{translate_difficulty_es}
      - Equipamiento disponible: #{translate_equipments_es}
      - Ingredientes deseados a incluir obligatoriamente: #{@recipe.ingredients_text}
      - Ingredientes PROHIBIDOS (NUNCA usar): #{@recipe.excluded_ingredients_text}

      #{contrainte_ingredients_es}

      #{contrainte_exclusions_es}

      #{contrainte_repas_froid_es}

      #{contrainte_healthy_es}

      #{contrainte_enfant_es}

      #{contrainte_orientale_es}

      #{contrainte_asiatique_es}

      #{contrainte_sans_preference_es}

      #{contrainte_fusion_es}

      #{contrainte_usa_es}

      #{contrainte_equipements_es}

      Responde en español con este formato exacto (usa el formato Markdown):

      ## [Nombre de la receta]

      **Tiempo de preparación:** [X minutos]
      **Tiempo de cocción:** [X minutos]
      **Dificultad:** #{translate_difficulty_es}
      **Calorías:** [X kcal por persona]

      ### Ingredientes (para #{@recipe.guests} persona#{'s' if @recipe.guests > 1})

      - [Ingrediente]: [cantidad precisa en gramos o unidades]
      - ...

      ### Preparación

      1. [Paso detallado con tiempo y temperatura si aplica]
      2. [Siguiente paso]
      3. ...

      ### Consejos del chef

      - [2-3 consejos prácticos para lograr la receta]
    PROMPT
  end

  # === Translation helpers for Spanish prompt ===

  CHOICE_ES = {
    'Entrée' => 'Entrada',
    'Plat principal' => 'Plato principal',
    'Dessert' => 'Postre'
  }.freeze

  DIET_ES = {
    'Sans restriction' => 'Sin restricción',
    'Sans gluten' => 'Sin gluten',
    'Diabétique' => 'Diabético',
    'Végétarien' => 'Vegetariano',
    'Healthy' => 'Healthy',
    'Enfant' => 'Niño'
  }.freeze

  CUISINE_ES = {
    'Sans préférence' => 'Sin preferencia',
    'Française' => 'Francesa',
    'Italienne' => 'Italiana',
    'Espagnole' => 'Española',
    'Sud-américaine' => 'Sudamericana',
    'Asiatique' => 'Asiática',
    'Indienne' => 'India',
    'Orientale' => 'Oriental',
    'Fusion(créative)' => 'Fusión(creativa)',
    'USA' => 'USA'
  }.freeze

  DURATION_ES = {
    'Express (<15mn)' => 'Express (<15min)',
    'Rapide (15-30mn)' => 'Rápido (15-30min)',
    'Classique (30-60mn)' => 'Clásico (30-60min)',
    'Élaboré (>60mn)' => 'Elaborado (>60min)'
  }.freeze

  DIFFICULTY_ES = {
    'Facile' => 'Fácil',
    'Moyen' => 'Medio',
    'Gastronomique' => 'Gastronómico'
  }.freeze

  EQUIPMENT_ES = {
    'Sans' => 'Sin',
    'Plaques de cuisson' => 'Placas de cocción',
    'Four' => 'Horno',
    'AirFryer' => 'AirFryer',
    'Thermomix' => 'Thermomix'
  }.freeze

  AGE_RANGE_ES = {
    '2 à 5 ans' => '2 a 5 años',
    '6 à 8 ans' => '6 a 8 años',
    '8 à 10 ans' => '8 a 10 años'
  }.freeze

  def translate_choice_es
    CHOICE_ES[@recipe.choice] || @recipe.choice
  end

  def translate_diet_es
    DIET_ES[@recipe.diet] || @recipe.diet
  end

  def translate_cuisine_es
    CUISINE_ES[@recipe.cuisine] || @recipe.cuisine
  end

  def translate_duration_es
    DURATION_ES[@recipe.duration] || @recipe.duration
  end

  def translate_difficulty_es
    DIFFICULTY_ES[@recipe.difficulty] || @recipe.difficulty
  end

  def translate_equipments_es
    return 'Ningún equipamiento especificado' if @recipe.equipments.blank?
    @recipe.equipments.map { |e| EQUIPMENT_ES[e] || e }.join(', ')
  end

  def translate_age_range_es
    AGE_RANGE_ES[@recipe.age_range] || @recipe.age_range
  end

  # === French constraints ===

  def contrainte_ingredients_fr
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
      ""
    end
  end

  def contrainte_exclusions_fr
    return "" if @recipe.excluded_ingredients.empty?

    <<~CONTRAINTE
      **CONTRAINTE STRICTE - INGRÉDIENTS INTERDITS:**
      Les ingrédients suivants sont ABSOLUMENT INTERDITS et ne doivent JAMAIS apparaître dans la recette: #{@recipe.excluded_ingredients_text}.
      Cela inclut ces ingrédients sous toutes leurs formes (frais, surgelés, en conserve, en poudre, etc.).
    CONTRAINTE
  end

  def contrainte_repas_froid_fr
    return "" unless @recipe.equipments&.include?('Sans')

    <<~CONTRAINTE
      **CONTRAINTE STRICTE - REPAS FROID:**
      L'utilisateur n'a PAS d'équipement de cuisson disponible. Tu DOIS proposer une recette FROIDE qui ne nécessite AUCUNE cuisson.
      Pas de plaques de cuisson, pas de four, pas d'airfryer, pas de thermomix.
      La recette doit pouvoir être préparée entièrement à froid (salades, tartares, carpaccios, verrines froides, sandwichs élaborés, etc.).
    CONTRAINTE
  end

  def contrainte_healthy_fr
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

  def contrainte_enfant_fr
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

  def contrainte_orientale_fr
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

  def contrainte_asiatique_fr
    return "" unless @recipe.cuisine == 'Asiatique'

    <<~CONTRAINTE
      **CONTRAINTE - CUISINE ASIATIQUE:**
      Exclure les recettes indiennes. Se concentrer sur les cuisines d'Asie de l'Est et du Sud-Est (Chine, Japon, Thaïlande, Vietnam, Corée, etc.).
    CONTRAINTE
  end

  def contrainte_sans_preference_fr
    return "" unless @recipe.cuisine == 'Sans préférence'

    <<~CONTRAINTE
      **CONTRAINTE - CUISINE SANS PRÉFÉRENCE (NEUTRE):**
      La recette doit être une cuisine neutre, sans saveurs typiquement régionales ou exotiques.

      ÉPICES ET INGRÉDIENTS À ÉVITER:
      - Curry, curcuma, garam masala et épices indiennes
      - Coriandre fraîche, citronnelle, nuoc-mâm, sauce soja
      - Piments, harissa, ras el hanout
      - Paprika fumé, chorizo, safran
      - Gingembre, wasabi, miso

      STYLE RECOMMANDÉ:
      - Cuisine simple et familiale
      - Assaisonnements classiques: sel, poivre, herbes de Provence, persil, ciboulette
      - Saveurs douces et accessibles à tous les palais
      - Recettes traditionnelles sans marqueur régional fort
    CONTRAINTE
  end

  def contrainte_fusion_fr
    return "" unless @recipe.cuisine == 'Fusion(créative)'

    <<~CONTRAINTE
      **CONTRAINTE - CUISINE FUSION (CRÉATIVE):**
      La recette doit être originale et créative, mélangeant des influences culinaires de différentes cultures.

      OBJECTIFS:
      - Créer des associations de saveurs inattendues mais harmonieuses
      - Mélanger des techniques de cuisines différentes (ex: technique française + saveurs asiatiques)
      - Oser des combinaisons originales (sucré-salé, textures contrastées)
      - Revisiter des classiques avec une touche moderne et inventive

      EXEMPLES D'ASSOCIATIONS:
      - Influence asiatique + européenne (ex: risotto au miso)
      - Influence mexicaine + méditerranéenne (ex: tacos au tzatziki)
      - Influence française + japonaise (ex: foie gras au yuzu)
      - Techniques modernes appliquées à des recettes traditionnelles

      IMPORTANT: La recette doit rester équilibrée et délicieuse, pas juste originale pour être originale.
    CONTRAINTE
  end

  def contrainte_usa_fr
    return "" unless @recipe.cuisine == 'USA'

    <<~CONTRAINTE
      **CONTRAINTE - CUISINE USA (AMÉRICAINE):**
      La recette doit être typiquement américaine (États-Unis).

      STYLES INCLUS:
      - Cuisine américaine classique (burgers, steaks, ribs, mac and cheese)
      - Cuisine du Sud (fried chicken, cajun, BBQ)
      - Diner américain (pancakes, cheesecake, brownies)
      - Fast-food revisité en version maison

      CUISINES STRICTEMENT EXCLUES:
      - Cuisine mexicaine (tacos, burritos, enchiladas, guacamole, nachos)
      - Cuisine sud-américaine (empanadas, ceviche, churrasco, arepas)
      - Cuisine tex-mex

      IMPORTANT: Même si certaines influences mexicaines sont présentes dans la culture culinaire américaine, cette recette doit rester 100% américaine traditionnelle.
    CONTRAINTE
  end

  def contrainte_equipements_fr
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

  # === Spanish constraints ===

  def contrainte_ingredients_es
    user_ingredients_count = @recipe.ingredients.count

    case @recipe.duration
    when 'Express (<15mn)'
      max_total = 4
      remaining = [max_total - user_ingredients_count, 0].max
      <<~CONTRAINTE
        **RESTRICCIÓN IMPORTANTE - RECETA EXPRESS:**
        La receta debe usar EXACTAMENTE #{max_total} ingredientes en total (excepto sal, pimienta, aceite).
        El usuario ya ha especificado #{user_ingredients_count} ingrediente(s) que DEBES incluir.
        Puedes añadir como máximo #{remaining} ingrediente(s) adicional(es).
        Esta es una restricción ESTRICTA para una receta rápida.
      CONTRAINTE
    when 'Rapide (15-30mn)'
      max_total = 5
      remaining = [max_total - user_ingredients_count, 0].max
      <<~CONTRAINTE
        **RESTRICCIÓN IMPORTANTE - RECETA RÁPIDA:**
        La receta debe usar EXACTAMENTE #{max_total} ingredientes en total (excepto sal, pimienta, aceite).
        El usuario ya ha especificado #{user_ingredients_count} ingrediente(s) que DEBES incluir.
        Puedes añadir como máximo #{remaining} ingrediente(s) adicional(es).
        Esta es una restricción ESTRICTA para una receta rápida.
      CONTRAINTE
    else
      ""
    end
  end

  def contrainte_exclusions_es
    return "" if @recipe.excluded_ingredients.empty?

    <<~CONTRAINTE
      **RESTRICCIÓN ESTRICTA - INGREDIENTES PROHIBIDOS:**
      Los siguientes ingredientes están ABSOLUTAMENTE PROHIBIDOS y NUNCA deben aparecer en la receta: #{@recipe.excluded_ingredients_text}.
      Esto incluye estos ingredientes en todas sus formas (frescos, congelados, en conserva, en polvo, etc.).
    CONTRAINTE
  end

  def contrainte_repas_froid_es
    return "" unless @recipe.equipments&.include?('Sans')

    <<~CONTRAINTE
      **RESTRICCIÓN ESTRICTA - COMIDA FRÍA:**
      El usuario NO tiene equipamiento de cocción disponible. DEBES proponer una receta FRÍA que no requiera NINGUNA cocción.
      Sin placas de cocción, sin horno, sin airfryer, sin thermomix.
      La receta debe poder prepararse completamente en frío (ensaladas, tartares, carpaccios, verrinas frías, sándwiches elaborados, etc.).
    CONTRAINTE
  end

  def contrainte_healthy_es
    return "" unless @recipe.diet == 'Healthy'

    <<~CONTRAINTE
      **RESTRICCIÓN ESTRICTA - RÉGIMEN HEALTHY:**
      La receta debe ser equilibrada y saludable, PERO seguir siendo sabrosa y deliciosa. DEBES respetar estas reglas:
      - Priorizar verduras frescas y de temporada
      - Usar proteínas magras (pollo, pescado, legumbres, tofu)
      - Evitar azúcares añadidos y grasas saturadas
      - Preferir cereales integrales a los refinados
      - Limitar la sal y usar hierbas y especias para condimentar
      - Favorecer cocciones suaves (vapor, horno, sartén con poca grasa)
      - IMPORTANTE: A pesar de estas restricciones, la receta debe seguir siendo sabrosa y gustosa. Usa combinaciones de sabores, especias, hierbas frescas y técnicas de cocción que realcen el sabor.
    CONTRAINTE
  end

  def contrainte_enfant_es
    return "" unless @recipe.diet == 'Enfant'

    <<~CONTRAINTE
      **RESTRICCIÓN ESTRICTA - RECETA PARA NIÑO (#{translate_age_range_es}):**
      Esta receta está destinada a un niño de #{translate_age_range_es}. DEBES respetar absolutamente estas reglas:

      ALIMENTOS ESTRICTAMENTE PROHIBIDOS:
      - Vísceras (hígado, riñones, etc.)
      - Chiles, especias fuertes o picantes
      - Cualquier ingrediente a base de alcohol (vino, cerveza, licor, incluso para desglasar)
      - Mariscos crudos
      - Carnes crudas o poco cocidas
      - Quesos de leche cruda
      - Miel (para menores de 3 años)

      REGLAS OBLIGATORIAS:
      - Cantidades adaptadas a la edad: porciones más pequeñas que un adulto
      - Texturas adaptadas a la edad (más tiernas para los 2-5 años)
      - Sabores suaves y poco salados
      - Poca o ninguna salsa (excepto salsa de tomate natural)
      - Presentación lúdica y colorida para atraer al niño
      - Alimentos fáciles de masticar y digerir

      IMPORTANTE: La receta debe seguir siendo apetitosa y sabrosa para gustar a los niños.
    CONTRAINTE
  end

  def contrainte_orientale_es
    return "" unless @recipe.cuisine == 'Orientale'

    <<~CONTRAINTE
      **RESTRICCIÓN ESTRICTA - COCINA ORIENTAL (HALAL):**
      Se trata de cocina del Norte de África y Oriente Medio (Israel no incluido).
      Esta receta debe respetar las reglas alimentarias halal. DEBES respetar absolutamente estas reglas:

      CARNES ESTRICTAMENTE PROHIBIDAS:
      - Cerdo y todos sus derivados (jamón, tocino, bacon, salchicha de cerdo, etc.)
      - Embutidos a base de cerdo
      - Gelatina de cerdo

      REGLAS OBLIGATORIAS:
      - Usar únicamente carne halal (cordero, ternera, pollo, pavo)
      - IMPORTANTE: Si la receta contiene carne, DEBES escribir "carne halal" en la lista de ingredientes (ej: "Pollo halal", "Carne picada halal", "Cordero halal")
      - Priorizar las especias orientales (comino, cilantro, canela, ras el hanout, cúrcuma)
      - Proponer sabores auténticos de la cocina oriental (Magreb, Oriente Medio)
    CONTRAINTE
  end

  def contrainte_asiatique_es
    return "" unless @recipe.cuisine == 'Asiatique'

    <<~CONTRAINTE
      **RESTRICCIÓN - COCINA ASIÁTICA:**
      Excluir las recetas indias. Concentrarse en las cocinas de Asia Oriental y del Sudeste (China, Japón, Tailandia, Vietnam, Corea, etc.).
    CONTRAINTE
  end

  def contrainte_sans_preference_es
    return "" unless @recipe.cuisine == 'Sans préférence'

    <<~CONTRAINTE
      **RESTRICCIÓN - COCINA SIN PREFERENCIA (NEUTRA):**
      La receta debe ser una cocina neutra, sin sabores típicamente regionales o exóticos.

      ESPECIAS E INGREDIENTES A EVITAR:
      - Curry, cúrcuma, garam masala y especias indias
      - Cilantro fresco, hierba limón, nuoc-mâm, salsa de soja
      - Chiles, harissa, ras el hanout
      - Pimentón ahumado, chorizo, azafrán
      - Jengibre, wasabi, miso

      ESTILO RECOMENDADO:
      - Cocina simple y familiar
      - Condimentos clásicos: sal, pimienta, hierbas provenzales, perejil, cebollino
      - Sabores suaves y accesibles para todos los paladares
      - Recetas tradicionales sin marca regional fuerte
    CONTRAINTE
  end

  def contrainte_fusion_es
    return "" unless @recipe.cuisine == 'Fusion(créative)'

    <<~CONTRAINTE
      **RESTRICCIÓN - COCINA FUSIÓN (CREATIVA):**
      La receta debe ser original y creativa, mezclando influencias culinarias de diferentes culturas.

      OBJETIVOS:
      - Crear combinaciones de sabores inesperadas pero armoniosas
      - Mezclar técnicas de cocinas diferentes (ej: técnica francesa + sabores asiáticos)
      - Atreverse con combinaciones originales (agridulce, texturas contrastantes)
      - Reinventar clásicos con un toque moderno e inventivo

      EJEMPLOS DE COMBINACIONES:
      - Influencia asiática + europea (ej: risotto con miso)
      - Influencia mexicana + mediterránea (ej: tacos con tzatziki)
      - Influencia francesa + japonesa (ej: foie gras con yuzu)
      - Técnicas modernas aplicadas a recetas tradicionales

      IMPORTANTE: La receta debe seguir siendo equilibrada y deliciosa, no solo original por ser original.
    CONTRAINTE
  end

  def contrainte_usa_es
    return "" unless @recipe.cuisine == 'USA'

    <<~CONTRAINTE
      **RESTRICCIÓN - COCINA USA (AMERICANA):**
      La receta debe ser típicamente americana (Estados Unidos).

      ESTILOS INCLUIDOS:
      - Cocina americana clásica (hamburguesas, steaks, costillas, mac and cheese)
      - Cocina del Sur (pollo frito, cajún, BBQ)
      - Diner americano (pancakes, cheesecake, brownies)
      - Comida rápida reinventada en versión casera

      COCINAS ESTRICTAMENTE EXCLUIDAS:
      - Cocina mexicana (tacos, burritos, enchiladas, guacamole, nachos)
      - Cocina sudamericana (empanadas, ceviche, churrasco, arepas)
      - Cocina tex-mex

      IMPORTANTE: Aunque ciertas influencias mexicanas están presentes en la cultura culinaria americana, esta receta debe ser 100% americana tradicional.
    CONTRAINTE
  end

  def contrainte_equipements_es
    contraintes = []

    if @recipe.equipments&.include?('Four')
      contraintes << <<~FOUR
        - **HORNO:** DEBES precisar si es necesario un precalentamiento (y a qué temperatura), la temperatura exacta de cocción en grados Celsius, y la duración precisa de cocción.
      FOUR
    end

    if @recipe.equipments&.include?('AirFryer')
      contraintes << <<~AIRFRYER
        - **AIRFRYER:** DEBES precisar la temperatura exacta en grados Celsius y la duración precisa de cocción.
      AIRFRYER
    end

    if @recipe.equipments&.include?('Thermomix')
      contraintes << <<~THERMOMIX
        - **THERMOMIX:** DEBES precisar la velocidad (1 a 10 o turbo), la temperatura exacta, y el tiempo de cocción para cada paso que use el Thermomix.
      THERMOMIX
    end

    return "" if contraintes.empty?

    <<~CONTRAINTE
      **INSTRUCCIONES ESPECÍFICAS PARA EL EQUIPAMIENTO:**
      #{contraintes.join}
    CONTRAINTE
  end
end
