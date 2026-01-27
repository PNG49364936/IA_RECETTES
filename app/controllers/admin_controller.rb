class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def index
    @users = User.all.order(created_at: :desc)
    @total_recipes = Recipe.count
    @total_users = User.count
  end

  def users
    @users = User.all.order(created_at: :desc)
  end

  def recipes
    @entrees = Recipe.where(choice: 'Entrée').order(created_at: :desc)
    @plats = Recipe.where(choice: 'Plat principal').order(created_at: :desc)
    @desserts = Recipe.where(choice: 'Dessert').order(created_at: :desc)
  end

  def show_recipe
    @recipe = Recipe.find(params[:id])
    @markdown_content = render_markdown(@recipe.content)
  end

  def destroy_user
    @user = User.find(params[:id])

    if @user.admin?
      redirect_to admin_users_path, alert: "Impossible de supprimer un administrateur"
      return
    end

    @user.recipes.destroy_all
    @user.destroy

    redirect_to admin_users_path, notice: "Utilisateur et ses recettes supprimés avec succès"
  end

  private

  def require_admin
    unless current_user.admin?
      redirect_to dashboard_path, alert: "Accès non autorisé"
    end
  end

  def render_markdown(text)
    return '' if text.blank?

    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(
        hard_wrap: true,
        link_attributes: { target: '_blank' }
      ),
      autolink: true,
      tables: true,
      fenced_code_blocks: true
    )
    markdown.render(text).html_safe
  end
end
