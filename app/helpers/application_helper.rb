module ApplicationHelper
  # Translate a DB value (stored in French) to the current locale display
  def translate_option(scope, value)
    return value if value.blank?
    key = value.parameterize(separator: '_')
    I18n.t("#{scope}.#{key}", default: value)
  end

  def translate_choice(value)
    translate_option('recipes.choices', value)
  end

  def translate_diet(value)
    translate_option('recipes.diets', value)
  end

  def translate_cuisine(value)
    translate_option('recipes.cuisines', value)
  end

  def translate_difficulty(value)
    translate_option('recipes.difficulties', value)
  end

  def translate_duration(value)
    translate_option('recipes.durations', value)
  end

  def translate_equipment(value)
    translate_option('recipes.equipments', value)
  end

  def translate_age_range(value)
    translate_option('recipes.age_ranges', value)
  end
end
