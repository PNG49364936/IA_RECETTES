class RecipesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recipe, only: [:show, :download_pdf, :destroy]

  def new
    @recipe = Recipe.new
  end

  def create
    @recipe = current_user.recipes.build(recipe_params)

    if @recipe.valid?
      service = ClaudeRecipeService.new(@recipe)
      @recipe.content = service.generate

      if @recipe.content.present?
        # Extraire le titre de la recette depuis le contenu Markdown
        @recipe.title = @recipe.extract_title_from_content

        # Stocker en cache temporairement (pas en BDD)
        @cache_key = "recipe_#{SecureRandom.hex(8)}"
        Rails.cache.write(@cache_key, {
          recipe_attributes: @recipe.attributes.except('id', 'created_at', 'updated_at'),
          user_id: current_user.id
        }, expires_in: 1.hour)

        @markdown_content = render_markdown(@recipe.content)
        @is_new_recipe = true
        render :show
      else
        flash.now[:alert] = "Une erreur s'est produite lors de la génération de la recette. Veuillez réessayer."
        render :new, status: :unprocessable_entity
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def save
    cache_key = params[:cache_key]
    cached_data = Rails.cache.read(cache_key)

    if cached_data && cached_data[:user_id] == current_user.id
      @recipe = current_user.recipes.build(cached_data[:recipe_attributes])

      if @recipe.save
        Rails.cache.delete(cache_key)
        redirect_to @recipe, notice: "Recette sauvegardée avec succès !"
      else
        redirect_to dashboard_path, alert: "Erreur lors de la sauvegarde."
      end
    else
      redirect_to dashboard_path, alert: "Recette expirée ou introuvable."
    end
  end

  def show
    @markdown_content = render_markdown(@recipe.content)
    @is_new_recipe = false
  end

  def destroy
    @recipe.destroy
    redirect_to dashboard_path, notice: "La recette a été supprimée."
  end

  def download_pdf
    @markdown_content = render_markdown(@recipe.content)

    render pdf: "recette",
           template: "recipes/download_pdf",
           layout: "pdf",
           encoding: "UTF-8",
           page_size: "A4",
           margin: { top: 20, bottom: 20, left: 20, right: 20 }
  end

  private

  def set_recipe
    @recipe = current_user.recipes.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to dashboard_path, alert: "Recette introuvable."
  end

  def recipe_params
    params.require(:recipe).permit(
      :choice, :guests, :diet, :age_range, :cuisine, :duration,
      :difficulty, :ingredient1, :ingredient2,
      :ingredient3, :ingredient4,
      :excluded1, :excluded2, :excluded3, :excluded4,
      equipments: []
    )
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
