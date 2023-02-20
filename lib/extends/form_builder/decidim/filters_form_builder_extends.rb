# frozen_string_literal: true

module DecidimFilterFormBuilderExtends
  # Wrap the radio buttons collection in a custom fieldset.
  # It also renders the inputs inside its labels.
  def collection_radio_buttons(method, collection, value_method, label_method, options = {}, html_options = {})
    Rails.cache.fetch("collection_radio_buttons/#{digest(method, collection, value_method, label_method, options, html_options)}") do
      fieldset_wrapper(options[:legend_title], "#{method}_collection_radio_buttons_filter") do
        super(method, collection, value_method, label_method, options, html_options) do |builder|
          if block_given?
            yield builder
          else
            builder.label { builder.radio_button + builder.text }
          end
        end
      end
    end
  end

  # Wrap the check_boxes collection in a custom fieldset.
  # It also renders the inputs inside its labels.
  def collection_check_boxes(method, collection, value_method, label_method, options = {}, html_options = {})
    Rails.cache.fetch("collection_check_boxes/#{digest(method, collection, value_method, label_method, options, html_options)}") do
      fieldset_wrapper(options[:legend_title], "#{method}_collection_check_boxes_filter") do
        super(method, collection, value_method, label_method, options, html_options) do |builder|
          if block_given?
            yield builder
          else
            builder.label { builder.check_box + builder.text }
          end
        end
      end
    end
  end

  # Wrap the dependant check_boxes in a custom fieldset.
  # checked parent checks its children
  def check_boxes_tree(method, collection, options = {})
    Rails.cache.fetch("check_boxes_tree/#{digest(method, collection, options)}") do
      fieldset_wrapper(options.delete(:legend_title), "#{method}_check_boxes_tree_filter") do
        @template.render("decidim/shared/check_boxes_tree",
                         form: self,
                         attribute: method,
                         collection: collection,
                         check_boxes_tree_id: check_boxes_tree_id(method),
                         hide_node: "false",
                         options: options).html_safe
      end
    end
  end

  # Wrap the category select in a custom fieldset.
  def categories_select(method, collection, options = {}, html_options = {})
    Rails.cache.fetch("categories_select/#{digest(method, collection, options, html_options)}") do
      fieldset_wrapper(options.delete(:legend_title), "#{method}_categories_select_filter") do
        super(method, collection, options, html_options)
      end
    end
  end

  # Wrap the areas select in a custom fieldset.
  def areas_select(method, collection, options = {}, html_options = {})
    Rails.cache.fetch("areas_select/#{digest(method, collection, options, html_options)}") do
      fieldset_wrapper(options[:legend_title], "#{method}_areas_select_filter") do
        super(method, collection, options, html_options)
      end
    end
  end

  # Wrap the custom select in a custom fieldset.
  # Any *_select can be used as a custom_select; what changes is the superclass method,
  # and this one knows which one has to be called, depending on the `name` provided.
  def custom_select(name, method, collection, options = {})
    Rails.cache.fetch("custom_select/#{digest(name, method, collection, options)}") do
      fieldset_wrapper(options[:legend_title], "#{method}_#{name}_select_filter") do
        send(:"#{name}_select", method, collection, options)
      end
    end
  end

  # Wrap the scopes picker in a custom fieldset.
  def scopes_picker(method, options = { checkboxes_on_top: true })
    Rails.cache.fetch("scopes_picker/#{digest(method, options)}") do
      fieldset_wrapper(options[:legend_title], "#{method}_scopes_picker_filter") do
        super(method, options)
      end
    end
  end

  private

  def digest(*args)
    Digest::MD5.hexdigest(args.map(&:to_s).join)
  end

  # Private: Renders a custom fieldset and execute the given block.
  def fieldset_wrapper(legend_title, extra_class)
    @template.content_tag(:div, "", class: "filters__section #{extra_class}") do
      @template.content_tag(:fieldset) do
        @template.content_tag(:legend, class: "mini-title") do
          legend_title
        end + yield
      end
    end
  end

  def check_boxes_tree_id(attribute)
    "#{attribute}-#{object_id}"
  end
end

Decidim::FilterFormBuilder.class_eval do
  prepend(DecidimFilterFormBuilderExtends)
end
