# Striving to produce forms mark-up as such:
# 
# <form>
#   <fieldset>
#     <legend>Some Context</legend>
#     <dl>
#       <dt><label for="someid">Name</label></dt>
#       <dd><input id="someid" ... /></dd>
#     <dl>
#   </fieldset>
# <form>
require 'validated_attributes'

class WebSgFormBuilder
  include ::ActionView::Helpers::TextHelper
  attr_accessor :builder

  def initialize(object_name, object, template, options, proc)
    @template = template
    @builder = ::ActionView::Helpers::FormBuilder.new(object_name, object, template, options, proc)
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
    concat("<fieldset><legend>#{name}</legend>\n  <dl>")
    proc.call(self)
    concat("</dl>\n</fieldset>")
  end
  
  def dl(&proc)
    concat("<dl>")
    proc.call(self)
    concat("</dl>")
  end
  
  def dd(label, hint = nil, &proc)
    if proc
      concat("<dt><label>#{label.to_s}</label> <span>#{hint}</span></dt><dd>")
      proc.call(self)
      concat("</dd>")
    else
      "<dt><label>#{label.to_s.humanize}</label> <span>#{hint}</span></dt><dd>" +
      CGI.escapeHTML(@builder.object.send(label).to_s) +
      "</dd>"
    end
  end
  
  def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
    label = options.delete(:label) || method.to_s.humanize
    @builder.check_box(method, options, checked_value, unchecked_value) +
    " " + label_tag_sg(@builder, label, method)
  end
  
  def radio_button(method, tag_value, options = {})
    label = options.delete(:label) || tag_value.to_s.humanize
    @builder.radio_button(method, tag_value, options) +
    " " + label_tag_sg(@builder, label, method, tag_value)
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
        label = opts.delete(:label) || method.to_s.humanize
        dt_class = opts.delete(:dt_class)
        dt_class_attr = dt_class ? " class=\"#{dt_class}\"" : ''
        dd_class = opts.delete(:dd_class) || dt_class
        dd_class_attr = dd_class ? " class=\"#{dd_class}\"" : ''
        
        hint  = opts.delete :hint
        "\n  <dt#{dt_class_attr}>" + label_tag_sg(@builder, label, method) +
          " <span>#{hint}</span></dt>\n  <dd#{dd_class_attr}" + 
        ">#{@builder.send(input_field, method, options, *args)}</dd>"
      end
    end
  end

  private

  def label_tag_sg(builder, label, *args)
    if args.length == 1
      builder.label(args.first, label)
    else
      field_id = CGI.escapeHTML(([builder.object_name] + args).join('_').downcase)
      "<label for=\"#{field_id}\">#{label}</label>"
    end
  end
end
