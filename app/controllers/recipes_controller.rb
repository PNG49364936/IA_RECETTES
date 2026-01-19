class RecipesController < ApplicationController
  def new
    @recipe = Recipe.new
  end

  def create
    @recipe = Recipe.new(recipe_params)

    if @recipe.valid?
      service = ClaudeRecipeService.new(@recipe)
      @recipe.response = service.generate

      if @recipe.response.present?
        # Stocker dans le cache Rails (pas de limite de taille)
        @cache_key = "recipe_#{SecureRandom.hex(8)}"
        data_to_cache = {
          response: @recipe.response,
          params: recipe_params.to_h
        }

        Rails.logger.info "========================================"
        Rails.logger.info "=== CREATE: Sauvegarde cache ==="
        Rails.logger.info "Cache key: #{@cache_key}"
        Rails.logger.info "Cache store: #{Rails.cache.class}"

        write_result = Rails.cache.write(@cache_key, data_to_cache, expires_in: 1.hour)
        Rails.logger.info "Write result: #{write_result}"

        # Vérification immédiate
        verify = Rails.cache.read(@cache_key)
        Rails.logger.info "Verification read: #{verify.present? ? 'OK' : 'FAILED'}"
        Rails.logger.info "========================================"

        @markdown_content = render_markdown(@recipe.response)
        render :show
      else
        flash.now[:alert] = "Une erreur s'est produite lors de la génération de la recette. Veuillez réessayer."
        render :new, status: :unprocessable_entity
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    cache_key = session[:recipe_cache_key]
    cached_data = cache_key.present? ? Rails.cache.read(cache_key) : nil

    if cached_data.present?
      @recipe = Recipe.new(cached_data[:params])
      @recipe.response = cached_data[:response]
      @markdown_content = render_markdown(@recipe.response)
    else
      redirect_to new_recipe_path, alert: "Aucune recette à afficher. Veuillez remplir le formulaire."
    end
  end

  def download_pdf
    cache_key = params[:key]

    Rails.logger.info "========================================"
    Rails.logger.info "=== PDF: Lecture cache ==="
    Rails.logger.info "Cache key from params: #{cache_key.inspect}"
    Rails.logger.info "Cache store: #{Rails.cache.class}"
    Rails.logger.info "All params: #{params.to_unsafe_h}"

    cached_data = cache_key.present? ? Rails.cache.read(cache_key) : nil
    Rails.logger.info "Cached data present?: #{cached_data.present?}"
    Rails.logger.info "========================================"

    if cached_data.present?
      @recipe = Recipe.new(cached_data[:params])
      @recipe.response = cached_data[:response]
      @markdown_content = render_markdown(@recipe.response)

      render pdf: "recette",
             template: "recipes/download_pdf",
             layout: "pdf",
             encoding: "UTF-8",
             page_size: "A4",
             margin: { top: 20, bottom: 20, left: 20, right: 20 }
    else
      redirect_to new_recipe_path, alert: "Aucune recette à télécharger."
    end
  end

  private

  def recipe_params
    params.require(:recipe).permit(
      :choice, :guests, :diet, :cuisine, :duration,
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
