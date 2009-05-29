# Striving to produce forms mark-up as such:
# 
# <form>
#   <fieldset>
#     <legend>Some Context</legend>
#     <div class="field">
#       <label for="someid">Name</label>
#       <input id="someid" ... />
#     </div>
#   </fieldset>
# <form>
require 'validated_attributes'

class WebSgFormBuilder
  include ::ActionView::Helpers::TextHelper
  attr_accessor :builder

  def initialize(object_name, object, template, options, proc)
    @template = template
    @builder = ::ActionView::Helpers::FormBuilder.new(object_name, object,
                                                      template, options, proc)
  end

  def fields_for(record_or_name_or_array, *args, &block)
    options = args.extract_options!
    options[:builder] = self.class
    args << options
    @builder.fields_for(record_or_name_or_array, *args, &block)
  end

  def concat(string)
    @template.concat(string)
  end

  def fieldset(name, &proc)
    concat("<fieldset><legend>#{name}</legend>\n")
    proc.call(self)
    concat("</fieldset>")
  end
  
  def check_box(method, options = {}, checked_value = "1",
                unchecked_value = "0")
    label = options.delete(:label)
    @builder.check_box(method, options, checked_value, unchecked_value) +
    " " + label_tag_sg(@builder, label, false, method)
  end

  # TODO: enclose in ul
  def radio_button(method, tag_value, options = {})
    label = options.delete(:label)
    @builder.radio_button(method, tag_value, options) +
    " " + label_tag_sg(@builder, label, false, method, tag_value)
  end

  def method_missing(input_field, *args)
    case input_field.to_s
    when /hidden|submit|button/
      @builder.send(input_field, *args)
    else
      if input_field.to_s =~ /=$/ || args.empty?
        @builder.send(input_field, *args)
      else
        # other tag helpers
        method = args.shift
        options = args.shift || {}
        # select has extra argument before options hash
        opts = options.kind_of?(Hash) ? options : args.first || {}
        label = opts.delete(:label)
        div_class = opts.delete(:div_class) || method.to_s
        
        hint  = opts.delete :hint
        "<div class=#{div_class}>\n  " +
          label_tag_sg(@builder, label, true, method) +
          " <span>#{hint}</span>\n  " + 
        "#{@builder.send(input_field, method, options, *args)}\n</div>"
      end
    end
  end

  private

  def label_tag_sg(builder, label, add_colon, method, tag_value = nil)
    label_text = label || (method.to_s.titleize + (add_colon ? ':' : ''))
    options = {}
    if tag_value
      field_id = CGI.escapeHTML([builder.object_name, method, tag_value].
                                join('_').downcase)
      options["for"] = field_id
    end
    builder.label(method, label_text, options)
  end
end
