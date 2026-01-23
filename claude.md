# Recettes IA - Spécifications

## Description
Application Rails de génération de recettes de cuisine via l'API Claude (modèle Sonnet), avec formulaire interactif, design Bootstrap responsive, export PDF, authentification utilisateur et sauvegarde en base de données. Interface entièrement en français.

## Technologies
- **Rails 7.1.6** avec Active Record
- **Ruby 3.2.2**
- **PostgreSQL** (Neon - hébergement cloud)
- **Devise** pour l'authentification
- **Bootstrap 5** via cssbundling-rails
- **Claude API** (modèle claude-sonnet-4-20250514, max_tokens: 2000)
- **WickedPDF** + wkhtmltopdf-binary pour l'export PDF
- **Redcarpet** pour le rendu Markdown
- **Rack::Attack** pour le rate limiting
- **dotenv-rails** pour les variables d'environnement

## Installation et lancement

```bash
# Installation des dépendances
bundle install
yarn install

# Configuration (créer le fichier .env)
ANTHROPIC_API_KEY=sk-ant-...
DATABASE_URL=postgresql://user:password@host/database?sslmode=require

# Création des tables
rails db:migrate

# Lancement du serveur de développement
bin/dev
```

Le serveur est accessible sur http://localhost:3000

## Architecture

### Base de données

```
Table "users" (Devise)
┌────────────────────────┬──────────┐
│ Colonne                │ Type     │
├────────────────────────┼──────────┤
│ id                     │ integer  │
│ email                  │ string   │
│ encrypted_password     │ string   │
│ reset_password_token   │ string   │
│ reset_password_sent_at │ datetime │
│ remember_created_at    │ datetime │
│ created_at             │ datetime │
│ updated_at             │ datetime │
└────────────────────────┴──────────┘

Table "recipes"
┌─────────────────────┬──────────┐
│ Colonne             │ Type     │
├─────────────────────┼──────────┤
│ id                  │ integer  │
│ user_id             │ integer  │
│ title               │ string   │
│ choice              │ string   │
│ guests              │ integer  │
│ diet                │ string   │
│ age_range           │ string   │
│ cuisine             │ string   │
│ duration            │ string   │
│ difficulty          │ string   │
│ equipments          │ text     │
│ ingredient1-4       │ string   │
│ excluded1-4         │ string   │
│ content             │ text     │
│ created_at          │ datetime │
│ updated_at          │ datetime │
└─────────────────────┴──────────┘
```

### Fichiers clés

```
app/
├── controllers/
│   ├── application_controller.rb  # Configuration Devise
│   ├── pages_controller.rb        # home, dashboard
│   └── recipes_controller.rb      # new, create, save, show, destroy, download_pdf
├── models/
│   ├── user.rb                    # Devise + has_many :recipes
│   └── recipe.rb                  # ActiveRecord + validations
├── services/
│   └── claude_recipe_service.rb   # Appel API Claude + construction prompt
├── views/
│   ├── layouts/
│   │   ├── application.html.erb   # Layout principal + modal connexion
│   │   └── pdf.html.erb           # Layout PDF
│   ├── pages/
│   │   ├── home.html.erb          # Page d'accueil publique
│   │   └── dashboard.html.erb     # Tableau de bord utilisateur
│   ├── recipes/
│   │   ├── new.html.erb           # Formulaire création recette
│   │   ├── show.html.erb          # Affichage recette
│   │   └── download_pdf.html.erb  # Template PDF
│   └── devise/                    # Vues authentification personnalisées
│       ├── sessions/
│       ├── registrations/
│       └── passwords/
└── assets/
    └── stylesheets/
        └── application.bootstrap.scss

config/
├── database.yml                   # Configuration PostgreSQL (Neon)
├── routes.rb                      # Routes application
├── locales/
│   └── fr.yml                     # Traductions françaises + Devise
└── initializers/
    ├── devise.rb                  # Configuration Devise
    ├── rack_attack.rb             # Rate limiting
    └── wicked_pdf.rb              # Configuration PDF
```

## Flux utilisateur

```
Page d'accueil (/)
    │
    ├── Non connecté → Modal connexion/inscription
    │                   ├── Se connecter
    │                   ├── Créer mon compte
    │                   └── Mot de passe oublié
    │
    └── Connecté → Tableau de bord (/dashboard)
                    │
                    ├── "Créer une recette" → Formulaire (/recipes/new)
                    │                              │
                    │                              └── Génération → Affichage recette
                    │                                               │
                    │                                               ├── Sauvegarder
                    │                                               ├── Nouvelle recette
                    │                                               └── Imprimer
                    │
                    └── "Consulter mes recettes" → Liste par catégorie
                                                    ├── Entrées
                                                    ├── Plats principaux
                                                    └── Desserts
                                                         │
                                                         └── Clic sur titre → Affichage recette
                                                                              │
                                                                              ├── Télécharger PDF
                                                                              ├── Supprimer
                                                                              └── Nouvelle recette
```

## Formulaire de saisie

### Rubriques

| Rubrique | Type | Options |
|----------|------|---------|
| Type de plat | Radio buttons | Entrée, Plat principal, Dessert |
| Nombre de convives | Select | 1-6 personnes |
| Régime et restrictions | Radio buttons | Sans restriction, Sans gluten, Diabétique, Végétarien, Healthy, Enfant |
| Tranche d'âge | Radio buttons | 2-5 ans, 6-8 ans, 8-10 ans (si Enfant) |
| Type de cuisine | Radio buttons | Française, Italienne, Espagnole, Sud-américaine, Asiatique, Indienne, Orientale |
| Niveau de difficulté | Radio buttons | Facile, Moyen, Gastronomique |
| Temps total | Radio buttons | Express (<15mn), Rapide (15-30mn), Classique (30-60mn), Élaboré (>60mn) |
| Équipement de cuisson | Checkboxes | Sans, Plaques de cuisson, Four, AirFryer, Thermomix |
| Ingrédients souhaités | 4 champs texte | Optionnel, max 4 |
| Ingrédients non autorisés | 4 champs texte | Optionnel, max 4 |

### Règles métier
- **Gastronomique + Express** : Combinaison interdite
- **Équipement "Sans"** : Génère un repas froid
- **Recettes Express** : Maximum 4 ingrédients (hors sel, poivre, huile)
- **Recettes Rapides** : Maximum 5 ingrédients (hors sel, poivre, huile)
- **Cuisine Orientale** : Pas de porc (halal)
- **Régime Enfant** : Aliments adaptés à l'âge

## Design

### Header
- Hauteur : 60px
- Couleur de fond : #1F509A
- Texte : blanc
- "Mon compte" à droite (modal connexion si non connecté)

### Couleurs
```scss
$primary-custom: #00F7FF;    // Cyan
$secondary-custom: #C4A77D;  // Beige doré
$background-custom: #FFF8F0; // Blanc cassé chaud
$text-custom: #4A3728;       // Marron foncé
$accent-custom: #D4574E;     // Rouge brique
$header-color: #1F509A;      // Bleu header
```

### Responsive
| Écran | Formulaire | Images | Boutons impression |
|-------|------------|--------|-------------------|
| Mobile (<768px) | 100% | Cachées | Cachés |
| Tablette (768-992px) | 100% | Cachées | Cachés |
| PC (>992px) | 70% | Visibles (30%) | Visibles |

## Fonctionnalités

### Authentification (Devise)
- Inscription avec email/mot de passe
- Connexion / Déconnexion
- Mot de passe oublié (reset par email)
- Sessions persistantes ("Se souvenir de moi")

### Page recette (show)
- Affichage du type de plat entre parenthèses
- **Nouvelle recette** : bouton "Sauvegarder la recette" (vert)
- **Recette sauvegardée** : boutons "Télécharger PDF" + "Supprimer la recette"
- **Imprimer** : `window.print()` (PC uniquement)

### Dashboard
- "Créer une recette" : lien vers le formulaire
- "Consulter mes recettes" : liste par catégorie (Entrées, Plats, Desserts)
- Affichage du titre uniquement dans la liste

## Sécurité

- Authentification obligatoire (Devise)
- Mots de passe hashés (bcrypt)
- Rate limiting : 10 recettes/heure par IP (Rack::Attack)
- Validation des entrées côté client (JS) et serveur (ActiveModel)
- Clé API dans `.env` (jamais commitée)
- Recettes liées à l'utilisateur (isolation des données)

## Configuration

### Variables d'environnement (.env)
```
ANTHROPIC_API_KEY=sk-ant-...
DATABASE_URL=postgresql://user:password@host/database?sslmode=require
```

### Routes
```ruby
devise_for :users
root 'pages#home'
get 'dashboard', to: 'pages#dashboard'
resources :recipes, only: [:new, :create, :show, :destroy] do
  member do
    get :download_pdf
  end
  collection do
    post :save
  end
end
```

## Déploiement

### Production : Render.com

**Variables d'environnement à configurer :**
- `ANTHROPIC_API_KEY` : Clé API Claude
- `DATABASE_URL` : URL de connexion Neon

**Commandes de build :**
```
bundle install && yarn install && bundle exec rails db:migrate && bundle exec rails assets:precompile
```

**Commande de démarrage :**
```
bundle exec puma -C config/puma.rb
```

### Base de données : Neon (PostgreSQL)

- Hébergement cloud serverless
- URL de connexion dans `DATABASE_URL`
- SSL requis (`sslmode=require`)
