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

- **Cible** : Render.com 
- **Distribution** : URL partagée (4-5 personnes)
- **Budget estimé** : ~10€/mois API Claude

### Checklist production
- [ ] Configurer `ANTHROPIC_API_KEY` dans les variables d'environnement
- [ ] Configurer le cache (Redis ou MemCachier)
- [ ] Vérifier que wkhtmltopdf est installé sur le serveur

## Instructions pour modification app :
# Plan de transition : Archivage des recettes en base de données

## 📋 Résumé de la situation actuelle

Votre application **Recettes IA** fonctionne actuellement :
- **Sans base de données** (`rails new --skip-active-record`)
- **Sans authentification** (usage familial)
- **Stockage temporaire** via le cache Rails (FileStore)
- **PDF généré à la volée** depuis le cache

### Pourquoi le PDF pose problème ?
Le PDF est généré depuis une recette stockée temporairement en cache. Si le cache expire ou si le serveur redémarre, la recette est perdue. Les utilisateurs ne peuvent pas retrouver leurs anciennes recettes.

---

## 🎯 Objectif de la transition

Permettre aux utilisateurs de :
1. **Créer un compte** (inscription/connexion)
2. **Sauvegarder leurs recettes** de façon permanente

3. **Télécharger les PDF** à tout moment

---

## 🏗️ Vue d'ensemble des changements

```
AVANT (actuel)                    APRÈS (cible)
─────────────────                 ─────────────────
Pas de BDD                   →    PostgreSQL
Pas d'authentification       →    Devise (gem)
Cache temporaire             →    Table "recipes"
1 seule recette accessible   →    Historique complet
```

---

## 📚 Étape 1 : Comprendre les concepts clés

### 1.1 Base de données relationnelle

Une base de données stocke vos données de façon permanente dans des **tables** (comme des tableaux Excel).

```
Table "users"                    Table "recipes"
┌────┬─────────┬──────────┐     ┌────┬─────────┬────────────┬─────────┐
│ id │ email   │ password │     │ id │ user_id │ title      │ content │
├────┼─────────┼──────────┤     ├────┼─────────┼────────────┼─────────┤
│ 1  │ a@b.com │ ******** │     │ 1  │ 1       │ Paella     │ ...     │
│ 2  │ c@d.com │ ******** │     │ 2  │ 1       │ Tiramisu   │ ...     │
└────┴─────────┴──────────┘     │ 3  │ 2       │ Ratatouille│ ...     │
                                 └────┴─────────┴────────────┴─────────┘
```

**Relation** : Chaque recette appartient à un utilisateur via `user_id`.

### 1.2 Authentification avec Devise

**Devise** est LA gem standard pour l'authentification Rails. Elle gère :
- Inscription / Connexion / Déconnexion
- Mot de passe oublié
- Sessions sécurisées
- Protection des pages

### 1.3 PostgreSQL vs SQLite

| Critère | SQLite | PostgreSQL |
|---------|--------|------------|
| Installation | Aucune (fichier local) | Serveur à configurer |
| Production | ❌ Non recommandé | ✅ Standard |
| Render.com | ❌ Non supporté | ✅ Inclus gratuitement |
| Coût | Gratuit | Gratuit (tier basique) |

**Recommandation** : PostgreSQL directement, pour éviter une seconde migration.

---

## 📚 Étape 2 : Choix d'hébergement de la base de données

### Option A : Render.com (recommandé pour vous)

Puisque vous ciblez déjà Render.com, c'est le plus simple.

| Service | Coût | Limites |
|---------|------|---------|
| PostgreSQL Free | 0€ | 1 Go, expire après 90 jours d'inactivité |
| PostgreSQL Starter | ~7$/mois | 1 Go, persistant |

**Avantages** : Tout au même endroit, configuration simplifiée.

### Option B : Services externes

| Service | Tier gratuit | Remarques |
|---------|--------------|-----------|
| 
| Neon | 512 Mo gratuit | Serverless, très rapide |


### Option C : Auto-hébergement





---

## 📚 Étape 3 : Plan de migration technique

### Phase 1 : Ajouter Active Record (1-2h)

```ruby
# 1. Modifier Gemfile - Ajouter :
gem 'pg'  # PostgreSQL

# 2. Créer config/database.yml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: 5

development:
  <<: *default
  database: recettes_ia_development

production:
  <<: *default
  url: <%= ENV['DATABASE_URL'] %>
```

```bash
# 3. Créer la base locale
rails db:create
```

### Phase 2 : Ajouter l'authentification Devise (2-3h)

```ruby
# 1. Gemfile
gem 'devise'

# 2. Installation
rails generate devise:install
rails generate devise User
rails db:migrate

# 3. Protéger les contrôleurs
class RecipesController < ApplicationController
  before_action :authenticate_user!
end
```

### Phase 3 : Créer le modèle Recipe avec persistance (2-3h)

```ruby
# 1. Générer la migration
rails generate model Recipe \
  user:references \
  title:string \
  dish_type:string \
  servings:integer \
  diet:string \
  cuisine:string \
  difficulty:string \
  time_range:string \
  equipment:text \
  desired_ingredients:text \
  forbidden_ingredients:text \
  content:text

# 2. Migrer
rails db:migrate

# 3. Modèle Recipe (remplace l'actuel)
class Recipe < ApplicationRecord
  belongs_to :user
  
  # Conserver vos validations actuelles
  validates :dish_type, presence: true
  # ... etc
  
  # Sérialisation pour les arrays
  serialize :equipment, Array
  serialize :desired_ingredients, Array
  serialize :forbidden_ingredients, Array
end

# 4. Modèle User
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  has_many :recipes, dependent: :destroy
end
```

### Phase 4 : Adapter le contrôleur (1-2h)

```ruby
class RecipesController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @recipes = current_user.recipes.order(created_at: :desc)
  end
  
  def create
    @recipe = current_user.recipes.build(recipe_params)
    
    if @recipe.valid?
      # Appel API Claude
      service = ClaudeRecipeService.new(@recipe)
      @recipe.content = service.generate
      @recipe.title = extract_title(@recipe.content)
      @recipe.save!
      
      redirect_to @recipe
    else
      render :new
    end
  end
  
  def show
    @recipe = current_user.recipes.find(params[:id])
  end
  
  def download_pdf
    @recipe = current_user.recipes.find(params[:id])
    # ... génération PDF
  end
  
  private
  
  def recipe_params
    params.require(:recipe).permit(
      :dish_type, :servings, :diet, :cuisine,
      :difficulty, :time_range,
      equipment: [], desired_ingredients: [], forbidden_ingredients: []
    )
  end
end
```

### Phase 5 : Ajouter la page d'historique (1-2h)

```erb
<!-- app/views/recipes/index.html.erb -->
<h1>Mes recettes</h1>

<% if @recipes.any? %>
  <div class="list-group">
    <% @recipes.each do |recipe| %>
      <a href="<%= recipe_path(recipe) %>" class="list-group-item">
        <h5><%= recipe.title %></h5>
        <small>
          <%= recipe.cuisine %> • <%= recipe.difficulty %> 
          • <%= l(recipe.created_at, format: :long) %>
        </small>
      </a>
    <% end %>
  </div>
<% else %>
  <p>Aucune recette sauvegardée.</p>
  <%= link_to "Générer ma première recette", new_recipe_path %>
<% end %>
```

---

## 📚 Étape 4 : Nouvelles routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  devise_for :users
  
  resources :recipes, only: [:index, :new, :create, :show] do
    member do
      get :download_pdf
    end
  end
  
  root 'recipes#index'  # Changement : index au lieu de new
end
```

**Nouveau flux utilisateur** :
```
Accueil (/) 
    │
    ├── Non connecté → Page de connexion
    │
    └── Connecté → Liste des recettes (index)
                        │
                        ├── "Nouvelle recette" → Formulaire (new)
                        │                              │
                        │                              └── Génération → Détail (show)
                        │
                        └── Clic sur une recette → Détail (show)
                                                        │
                                                        └── Télécharger PDF
```

---

## 📚 Étape 5 : Déploiement sur Render.com

### 5.1 Créer la base de données

1. Dashboard Render → **New** → **PostgreSQL**
2. Nom : `recettes-ia-db`
3. Plan : Free ou Starter
4. Région : Frankfurt (plus proche)
5. **Create Database**

### 5.2 Connecter l'application

1. Copier l'**Internal Database URL**
2. Dans votre Web Service → **Environment**
3. Ajouter : `DATABASE_URL` = (l'URL copiée)

### 5.3 Commandes de build

```yaml
# render.yaml ou dans l'interface
buildCommand: bundle install && yarn install && bundle exec rails db:migrate && bundle exec rails assets:precompile
startCommand: bundle exec puma -C config/puma.rb
```

---


---

## ✅ Checklist avant de commencer

### Prérequis techniques
- [ ] PostgreSQL installé localement (`brew install postgresql` sur Mac)
- [ ] Compte Render.com créé
- [ ] Git configuré avec commits réguliers

### Décisions à prendre
- [ ] Budget mensuel accepté (~24€/mois recommandé)
- [ ] Voulez-vous une page d'inscription publique ou gérer les comptes manuellement ?
- [ ] Voulez-vous un email de confirmation à l'inscription ?

### Sauvegardes
- [ ] Commit Git avant toute modification
- [ ] Copie du fichier `claude.md` actuel

---

## 🚀 Par où commencer ?

**Je recommande cette approche progressive** :

1. **D'abord en local** : Faites toutes les modifications sur votre machine
2. **Testez abondamment** : Créez plusieurs comptes, plusieurs recettes
3. **Puis déployez** : Une fois que tout fonctionne localement

**Première action concrète** :
```bash
# Créer une branche de travail
git checkout -b feature/database-authentication

# Installer PostgreSQL si nécessaire
# Mac : brew install postgresql && brew services start postgresql
# Ubuntu : sudo apt install postgresql
```

### A prendre en compte
- utilisation de neon.
- il faudra creer une page d'accueil :
   - avec header
   - main.

   Header : 
   - 3 cms de haut
   - color font : blanc
   - back ground color : 1F509A
   - sur la droite : "mon compte"
     en cliquant sur mon compte :
        un formulaire avec :
        - adress-mail à renseigner
        - mot de passe
        - Me connecter
        - mot de passe oublié
        - créer mon compte.
        (tous les back-end de ces rubriques à créer)

    si l'utilisateur se commecte.
    - nouvel écran.
    - prevoir header 3 cms (sera adapté plus tard graphiquement)

    - l'utilisateur :
    - pourra valider sur cette page :
         - creer recette (link vers views/recipe/new)
         - Consulter mes recettes.
           en validant, affichage de entree, plat principal,dessert.
           (présentation verticale)
         - lorsque l utilisateur cliquera sur "entrée", les recettes sauvegardée s'afficheront, idem pour plats principales, etc.

    lors de l'affichage de la recette, prevoir bouton "Supprimer la recette"
    (sur PC et mobil)

    ### TRES IMPORTANT.
    Les recettes doivent être identifiées comme : Entrée, plat principal, dessert.
    Lorsqu'un recette est crée et affichée, cett mentions (entree, plat princiapl, dessert) doit être aussi visible entre (). Show.erb (ligne 5)

      

    ne pas demander de validation dans les modifications de code