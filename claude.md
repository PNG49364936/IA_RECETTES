# Recettes IA - Spécifications

## Description
Application Rails de génération de recettes de cuisine via l'API Claude (modèle Sonnet), avec formulaire interactif, design Bootstrap responsive et export PDF. Interface entièrement en français, sans stockage en base de données.

## Technologies
- **Rails 7.1.6** avec `--skip-active-record` (pas de BDD)
- **Ruby 3.2.2**
- **Bootstrap 5** via cssbundling-rails
- **Claude API** (modèle claude-sonnet-4-20250514, max_tokens: 4000)
- **WickedPDF** + wkhtmltopdf-binary pour l'export PDF
- **Redcarpet** pour le rendu Markdown
- **Rack::Attack** pour le rate limiting
- **dotenv-rails** pour les variables d'environnement

## Installation et lancement

```bash
# Installation des dépendances
bundle install
yarn install

# Configuration de la clé API (créer le fichier .env)
echo "ANTHROPIC_API_KEY=sk-ant-..." > .env

# Lancement du serveur de développement
bin/dev
```

Le serveur est accessible sur http://localhost:3000

## Formulaire de saisie

### Rubriques

| Rubrique | Type | Options |
|----------|------|---------|
| Type de plat | Radio buttons | Entrée, Plat principal, Dessert |
| Nombre de convives | Select | 1-6 personnes |
| Régime et restrictions | Radio buttons | Sans restriction, Sans gluten, Diabétique, Végétarien |
| Type de cuisine | Radio buttons | Française, Italienne, Espagnole, Sud-américaine, Asiatique, Indienne |
| Niveau de difficulté | Radio buttons | Facile, Moyen, Gastronomique |
| Temps total | Radio buttons | Express (<15mn), Rapide (15-30mn), Classique (30-60mn), Élaboré (>60mn) |
| Équipement de cuisson | Checkboxes | Sans, Plaques de cuisson, Four, AirFryer, Thermomix |
| Ingrédients souhaités | 4 champs texte | Optionnel, max 4 |
| Ingrédients non autorisés | 4 champs texte | Optionnel, max 4 |

### Règles métier
- **Gastronomique + Express** : Combinaison interdite (alerte toast + blocage JS + validation serveur)
- **Équipement "Sans"** : Désactive les autres équipements, génère un repas froid
- **Recettes Express** : Maximum 4 ingrédients (hors sel, poivre, huile)
- **Recettes Rapides** : Maximum 5 ingrédients (hors sel, poivre, huile)

## Design

### Couleurs
```scss
$primary-custom: #00F7FF;    // Cyan (bannière, boutons)
$secondary-custom: #C4A77D;  // Beige doré
$background-custom: #FFF8F0; // Blanc cassé chaud
$text-custom: #4A3728;       // Marron foncé
$accent-custom: #D4574E;     // Rouge brique
```

### Éléments visuels
- **Bannière** : Cyan avec effet de pliage, 80% largeur
- **Images décoratives** : Paella, Pizza, Poulet-frites (colonne droite, PC uniquement)
- **Notifications** : Toasts Bootstrap (pas d'alert() natifs)
- **Chargement** : Overlay animé avec spinner et messages rotatifs

### Responsive
| Écran | Formulaire | Images | Boutons impression |
|-------|------------|--------|-------------------|
| Mobile (<768px) | 100% | Cachées | Cachés |
| Tablette (768-992px) | 100% | Cachées | Cachés |
| PC (>992px) | 70% | Visibles (30%) | Visibles |

## Format de la recette générée

```markdown
## [Nom de la recette]

**Temps de préparation:** [X minutes]
**Temps de cuisson:** [X minutes]
**Difficulté:** [niveau]

### Ingrédients (pour X personnes)
- [Ingrédient]: [quantité précise]
- ...

### Préparation
1. [Étape détaillée]
2. ...

### Conseils du chef
- [2-3 conseils pratiques]
```

## Fonctionnalités

### Page recette (show)
- **Nouvelle recette** : Retour au formulaire
- **Imprimer** : `window.print()` (PC uniquement)
- **Télécharger PDF** : Export via WickedPDF (PC uniquement)

### Messages d'erreur
Format : `[Champ] → [message]`
Exemple : `Type de plat → doit être renseigné`

### Indicateur de chargement
Messages rotatifs pendant la génération :
1. "Analyse de vos préférences..."
2. "Sélection des meilleurs ingrédients..."
3. "Notre chef prépare votre recette..."
4. "Rédaction des étapes de préparation..."
5. "Calcul des quantités..."
6. "Ajout des conseils du chef..."
7. "Finalisation de votre recette..."

## Sécurité

- Pas d'authentification (usage familial)
- Rate limiting : 10 recettes/heure par IP (Rack::Attack)
- Validation des entrées côté client (JS) et serveur (ActiveModel)
- Clé API dans `.env` (jamais commitée, dans .gitignore)

## Configuration

### Variables d'environnement
```
ANTHROPIC_API_KEY=sk-ant-...
```

### Cache (stockage temporaire des recettes)
- **Développement** : `FileStore` (tmp/cache) - persiste entre les requêtes
- **Production** : À configurer selon hébergeur (Redis recommandé)

⚠️ **Important** : Ne pas utiliser `NullStore` en développement, sinon le PDF ne fonctionnera pas.

### Fichiers clés
```
app/
├── controllers/
│   └── recipes_controller.rb      # Actions new, create, show, download_pdf
├── models/
│   └── recipe.rb                  # ActiveModel avec validations
├── services/
│   └── claude_recipe_service.rb   # Appel API Claude + construction prompt
├── views/
│   ├── layouts/
│   │   ├── application.html.erb   # Layout principal
│   │   └── pdf.html.erb           # Layout PDF
│   └── recipes/
│       ├── new.html.erb           # Formulaire + JS validations
│       ├── show.html.erb          # Affichage recette
│       └── download_pdf.html.erb  # Template PDF
└── assets/
    ├── images/
    │   ├── paella.jpg
    │   ├── pizza.jpg
    │   └── poulet-frites.jpg
    └── stylesheets/
        └── application.bootstrap.scss  # Styles personnalisés

config/
├── routes.rb                      # Routes de l'application
├── locales/
│   └── fr.yml                     # Traductions (non utilisé, messages dans le modèle)
├── environments/
│   └── development.rb             # Cache FileStore activé
└── initializers/
    ├── rack_attack.rb             # Rate limiting
    └── wicked_pdf.rb              # Configuration PDF
```

## Déploiement

- **Cible** : Render.com ou Fly.io
- **Distribution** : URL partagée (4-5 personnes)
- **Budget estimé** : ~10€/mois API Claude

### Checklist production
- [ ] Configurer `ANTHROPIC_API_KEY` dans les variables d'environnement
- [ ] Configurer le cache (Redis ou MemCachier)
- [ ] Vérifier que wkhtmltopdf est installé sur le serveur
