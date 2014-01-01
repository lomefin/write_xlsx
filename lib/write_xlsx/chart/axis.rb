# -*- encoding: utf-8 -*-
require 'write_xlsx/package/xml_writer_simple'
require 'write_xlsx/utility'
require 'write_xlsx/chart/caption'

module Writexlsx
  class Chart
    class Axis < Caption
      include Writexlsx::Utility

      attr_accessor :defaults, :reverse
      attr_accessor :min, :max
      attr_accessor :minor_unit, :major_unit, :minor_unit_type, :major_unit_type
      attr_accessor :log_base, :crossing, :position, :position_axis, :label_position, :visible
      attr_accessor :num_format, :num_format_linked, :num_font, :layout, :interval_unit
      attr_accessor :major_gridlines, :minor_gridlines, :major_tick_mark

      #
      # Convert user defined axis values into axis instance.
      #
      def merge_with_hash(params) # :nodoc:
        super
        args      = (defaults || {}).merge(params)

        @reverse           = args[:reverse]
        @min               = args[:min]
        @max               = args[:max]
        @minor_unit        = args[:minor_unit]
        @major_unit        = args[:major_unit]
        @minor_unit_type   = args[:minor_unit_type]
        @major_unit_type   = args[:major_unit_type]
        @log_base          = args[:log_base]
        @crossing          = args[:crossing]
        @position_axis     = args[:position_axis]
        @label_position    = args[:label_position]
        @num_format        = args[:num_format]
        @num_format_linked = args[:num_format_linked]
        @interval_unit     = args[:interval_unit]
        @visible           = args[:visible] || 1

        # Map major/minor_gridlines properties.
        [:major_gridlines, :minor_gridlines].each do |lines|
          if args[lines] && ptrue?(args[lines][:visible])
            instance_variable_set("@#{lines}", Gridline.new(args[lines]))
          else
            instance_variable_set("@#{lines}", nil)
          end
        end
        @major_tick_mark   = args[:major_tick_mark]

        # Only use the first letter of bottom, top, left or right.
        @position = args[:position]
        @position = @position.downcase[0, 1] if @position

        # Set the position for a category axis on or between the tick marks.
        if @position_axis
          if @position_axis == 'on_tick'
            @position_axis = 'midCat'
          elsif @position_axis == 'between'
            # Doesn't neet to be modified.
          else
            # Otherwise use the default value.
            @position_axis = nil
          end
        end

        # Set the font properties if present.
        @num_font  = @chart.convert_font_args(args[:num_font])
        @name_font = @chart.convert_font_args(args[:name_font])

        # Set the axis name layout.
        @layout    = @chart.layout_properties(args[:name_layout], 1)
      end

      #
      # Write the <c:numberFormat> element. Note: It is assumed that if a user
      # defined number format is supplied (i.e., non-default) then the sourceLinked
      # attribute is 0. The user can override this if required.
      #

      def write_number_format(writer) # :nodoc:
        source_linked = 1

        # Check if a user defined number format has been set.
        if @defaults && @num_format != @defaults[:num_format]
          source_linked = 0
        end

        # User override of sourceLinked.
        if ptrue?(@num_format_linked)
          source_linked = 1
        end

        attributes = [
                      ['formatCode',   @num_format],
                      ['sourceLinked', source_linked]
                     ]

        writer.empty_tag('c:numFmt', attributes)
      end

      #
      # Write the <c:numFmt> element. Special case handler for category axes which
      # don't always have a number format.
      #
      def write_cat_number_format(writer, cat_has_num_fmt)
        source_linked  = 1
        default_format = true

        # Check if a user defined number format has been set.
        if @defaults && @num_format != @defaults[:num_format]
          source_linked  = 0
          default_format = false
        end

        # User override of linkedSource.
        if @num_format_linked
          source_linked = 1
        end

        # Skip if cat doesn't have a num format (unless it is non-default).
        if !cat_has_num_fmt && default_format
          return ''
        end

        attributes = [
                      ['formatCode',   @num_format],
                      ['sourceLinked', source_linked]
                     ]

        writer.empty_tag('c:numFmt', attributes)
      end
    end
  end
end