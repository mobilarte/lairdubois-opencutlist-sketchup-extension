﻿module Ladb::OpenCutList

  require 'singleton'

  class DimensionUtils

    # Format - just here for convenience
    DECIMAL       = Length::Decimal
    ARCHITECTURAL = Length::Architectural
    ENGINEERING   = Length::Engineering
    FRACTIONAL    = Length::Fractional

    # Unit - just here for convenience
    INCHES        = Length::Inches
    FEET          = Length::Feet
    YARD          = Sketchup.version_number >= 2000000000 ? Length::Yard : 5
    MILLIMETER    = Length::Millimeter
    CENTIMETER    = Length::Centimeter
    METER         = Length::Meter

    # Unit symbols
    UNIT_SYMBOL_INCHES = '"'
    UNIT_SYMBOL_FEET = "'"
    UNIT_SYMBOL_YARD = "yd"
    UNIT_SYMBOL_METER = 'm'
    UNIT_SYMBOL_CENTIMETER = 'cm'
    UNIT_SYMBOL_MILLIMETER = 'mm'

    UNIT_SYMBOL_METER_2 = 'm²'
    UNIT_SYMBOL_FEET_2 = 'ft²'

    UNIT_SYMBOL_METER_3 = 'm³'
    UNIT_SYMBOL_FEET_3 = 'ft³'
    UNIT_SYMBOL_BOARD_FEET = 'FBM'

    # Unit strippednames
    UNIT_STRIPPEDNAME_INCHES = 'in'
    UNIT_STRIPPEDNAME_FEET = "ft"
    UNIT_STRIPPEDNAME_YARD = "yd"
    UNIT_STRIPPEDNAME_METER = 'm'
    UNIT_STRIPPEDNAME_CENTIMETER = 'cm'
    UNIT_STRIPPEDNAME_MILLIMETER = 'mm'

    UNIT_STRIPPEDNAME_METER_2 = 'm2'
    UNIT_STRIPPEDNAME_FEET_2 = 'ft2'

    UNIT_STRIPPEDNAME_METER_3 = 'm3'
    UNIT_STRIPPEDNAME_FEET_3 = 'ft3'
    UNIT_STRIPPEDNAME_BOARD_FEET = 'fbm'

    include Singleton

    attr_accessor :decimal_separator, :length_unit, :length_format, :length_precision

    LENGTH_MIN_PRECISION = 3

    # Separators
    LIST_SEPARATOR = ';'.freeze
    DXD_SEPARATOR = 'x'.freeze

    @decimal_separator
    @length_unit
    @length_format
    @length_precision

    # -----

    def initialize
      begin
        '1.0'.to_l
        @decimal_separator = '.'
      rescue
        @decimal_separator = ','
      end
      fetch_length_options
    end

    def fetch_length_options
      model = Sketchup.active_model
      @length_unit = model ? model.options['UnitsOptions']['LengthUnit'] : MILLIMETER
      @length_format = model ? model.options['UnitsOptions']['LengthFormat'] : DECIMAL
      @length_precision = model ? model.options['UnitsOptions']['LengthPrecision'] : 0
    end

    # Set unit length for Tests only!
    def set_length_unit(unit)
      @length_unit = unit
      model = Sketchup.active_model
      model.options['UnitsOptions']['LengthUnit'] = unit
    end

    # -----

    def ocl_length_precision
      [ LENGTH_MIN_PRECISION, @length_precision ].max
    end

    # Take a Length, convert to float in inches rounded to "OpenCutList" precision
    def to_ocl_precision_f(l)
      l.to_f.round(ocl_length_precision)
    end

    # Take a Length, convert to string representation in model unit rounded to "OpenCutList" precision
    def to_ocl_precision_s(l)
      Sketchup.format_length(l, ocl_length_precision).gsub(/~ /, '') # Remove ~ if it exists
    end

    # Check if given length value is rounded by model precision
    def rounded_by_model_precision?(f)
      precision = ocl_length_precision
      f.to_l.to_s.to_l.to_f.round(precision) != f.to_l.to_f.round(precision)
    end

    # -----

    def model_units_to_inches(i)
      case @length_unit
      when MILLIMETER
        return i / 25.4
      when CENTIMETER
        return i / 2.54
      when METER
        return i / 0.0254
      when FEET
        return i * 12
      when YARD
        return i * 36
      else
        return i
      end
    end

    def unit_sign
      case @length_unit
        when MILLIMETER
          return UNIT_SYMBOL_MILLIMETER
        when CENTIMETER
          return UNIT_SYMBOL_CENTIMETER
        when METER
          return UNIT_SYMBOL_METER
        when FEET
          return UNIT_SYMBOL_FEET
        when YARD
          return UNIT_SYMBOL_YARD
        else
          return UNIT_SYMBOL_INCHES
      end
    end

    def model_unit_is_metric
      case @length_unit
        when MILLIMETER, CENTIMETER, METER
          return true
        else
          return false
      end
    end

    # Take a single dimension as a string and
    # 1. add units if none are present, assuming that no units means model units
    # 2. convert garbage into 0
    #
    def str_add_units(s)
      return '0'.to_l.to_s if s.nil? || s.empty?
      s = s.strip
      s = s.gsub(/,/, @decimal_separator) # convert separator to native
      s = s.gsub(/\./, @decimal_separator) # convert separator to native
      nb = "0.0"

      if s.is_a?(String)
        unit_present = false
        # cannot use m and mm in the same regexp!
        if (match = s.match(/\A.*(cm|mm|\'|\"|yd)+.*\z/)) || (match = s.match(/\A.*(m)+.*\z/))
          unit, = match.captures
          puts("parsed unit = #{unit} in #{s}")
          nb = s.gsub(/\s*#{unit}\s*/, "#{unit}") # remove space around unit
          unit_present = true
        end
        begin # try to convert to length
          x = s.to_l
        rescue => e
          puts("OCL [dimension input error]: #{e}")
          s = "0.0"
        end
        if !unit_present
          puts("default unit = #{unit_sign()} in #{s}")
          nb = s + unit_sign()
        end
      end
      nb
    end

    # Takes a single dimension as a string and converts it into a
    # decimal inch.
    # Returns the float as a string
    #
    def str_to_ifloat(s)
      s = s.sub(/~/, '') # strip approximate sign away
      s = s.strip
      s = s.gsub(/,/, @decimal_separator) # convert separator to native
      s = s.gsub(/\./, @decimal_separator) # convert separator to native
      nb = "0.0" # default value if conversion fails!

      # make sure the entry is a string and starts with the proper magic
      if s.is_a?(String)
        s = s.gsub(/\s*\/\s*/, '/') # remove blanks around /
        puts("start = #{s}")
        begin
          nb = ((s.to_l).to_f).to_s
        rescue => e
          puts("OCL [dimension input error]: #{e}")
        end
      end
      puts("#{s} => #{nb}#{UNIT_SYMBOL_INCHES}")
      nb = nb.gsub(/\./, @decimal_separator) + UNIT_SYMBOL_INCHES
    end

    # Takes a single number in a string and converts it to a string
    # in Sketchup internal format (inches, decimal) with unit sign
    #
    def str_to_istr(s)
      str_to_ifloat(s)
    end

    # Splits a string in the form d;d;...
    # into single d's and applies the function fn to each element
    # returns the concatenated string in the same format
    #
    def d_transform(i, fn)
      return '' if i.nil?
      a = i.split(LIST_SEPARATOR)
      r = []
      a.each do |e|
        r << send(fn, e)
      end
      r.join(LIST_SEPARATOR)
    end

    def d_add_units(i)
      d_transform(i, :str_add_units)
    end

    def d_to_ifloats(i)
      d_transform(i, :str_to_ifloat)
    end

    # Splits a string in the form dxd;dxd;...
    # into single d's and applies the function fn to each element
    # returns the concatenated string in the same format
    #
    def dxd_transform(i, fn)
      return '' if i.nil?
      a = i.split(LIST_SEPARATOR)
      r = []
      a.each do |e|
        ed = e.split(DXD_SEPARATOR)
        ed[0] = '0' if ed[0].nil? || ed[0].empty?
        ed[1] = '0' if ed[1].nil? || ed[1].empty?
        r << (send(fn, ed[0]) + ' ' + DXD_SEPARATOR + ' ' + send(fn, ed[1]))
      end
      r.join(LIST_SEPARATOR)
    end

    # Take a string containing dimensions in the form dxd;dxd;dxd;...
    # and make sure they all have units and are not empty
    # without units, model units are assumed and added
    #
    def dxd_add_units(i)
      dxd_transform(i, :str_add_units)
    end

    # Take a string containing dimensions in the form dxd;dxd;dxd;...
    # and convert them into a decimal inch number (Sketchup internal
    # format)
    # the number is returned as a string NOT a length or float
    #
    def dxd_to_ifloats(i)
      dxd_transform(i, :str_to_ifloat)
    end

    # Splits a string in the form dxq;dxq;...
    # into single d's and applies the function fn to each element. q stay unchanged.
    # returns the concatenated string in the same format
    #
    def dxq_transform(i, fn)
      return '' if i.nil?
      a = i.split(LIST_SEPARATOR)
      r = []
      a.each do |e|
        ed = e.split(DXD_SEPARATOR)
        ed[0] = '0' if ed[0].nil? || ed[0].empty?
        ed[1] = '0' if ed[1].nil? || ed[1].empty? || ed[1].strip.to_i < 1
        r << (send(fn, ed[0]) + (ed[1] == '0' ? '' : ' ' + DXD_SEPARATOR + ed[1].strip))
      end
      r.join(LIST_SEPARATOR)
    end

    # Take a string containing dimensions in the form dxq;dxq;dxq;...
    # and make sure they all have units and are not empty
    # without units, model units are assumed and added
    #
    def dxq_add_units(i)
      dxq_transform(i, :str_add_units)
    end

    # Take a string containing dimensions in the form dxq;dxq;dxq;...
    # and convert them into a decimal inch number (Sketchup internal
    # format)
    # the number is returned as a string NOT a length or float
    #
    def dxq_to_ifloats(i)
      dxq_transform(i, :str_to_ifloat)
    end

    # Splits a string in the form dxdxq;dxdxq;...
    # into single d's and applies the function f to each element. q stay unchanged.
    # returns the concatenated string in the same format
    #
    def dxdxq_transform(i, f)
      return '' if i.nil?
      a = i.split(LIST_SEPARATOR)
      r = []
      a.each do |e|
        ed = e.split(DXD_SEPARATOR)
        ed[0] = '0' if ed[0].nil? || ed[0].empty?
        ed[1] = '0' if ed[1].nil? || ed[1].empty?
        ed[2] = '0' if ed[2].nil? || ed[2].empty? || ed[2].strip.to_i < 1
        r << (send(f, ed[0]) + ' ' + DXD_SEPARATOR + ' ' + send(f, ed[1]) + (ed[2] == '0' ? '' :  ' ' + DXD_SEPARATOR + ed[2].strip))
      end
      r.join(LIST_SEPARATOR)
    end

    # Take a string containing dimensions in the form dxdxq;dxdxq;dxdxq;...
    # and make sure they all have units and are not empty
    # without units, model units are assumed and added
    #
    def dxdxq_add_units(i)
      dxdxq_transform(i, :str_add_units)
    end

    # Take a string containing dimensions in the form dxdxq;dxdxq;dxdxq;...
    # and convert them into a decimal inch number (Sketchup internal
    # format)
    # the number is returned as a string NOT a length or float
    #
    def dxdxq_to_ifloats(i)
      dxdxq_transform(i, :str_to_ifloat)
    end

    # -----

    def m3_to_inch3(f)
      f * 0.0254**3
    end

    def ft3_to_inch3(f)
      f / 12**3
    end

    def fbm_to_inch3(f)
      f / 12**2
    end


    def m2_to_inch2(f)
      f * 0.0254**2
    end

    def ft2_to_inch2(f)
      f / 12**2
    end


    def m_to_inch(f)
      f * 0.0254
    end

    def ft_to_inch(f)
      f / 12
    end

    # -----

    # Take a float containing a length in inch
    # and convert it to a string representation according to the
    # model unit settings.
    #
    def format_to_readable_length(f)
      if f.nil?
        return nil
      end
      if model_unit_is_metric
        multiplier = 0.0254
        precision = [2, @length_precision].max
        unit_strippedname = UNIT_STRIPPEDNAME_METER
      else
        multiplier = 1 / 12.0
        precision = [2, @length_precision].max
        unit_strippedname = UNIT_STRIPPEDNAME_FEET
      end
      UnitUtils.format_readable(f * multiplier, unit_strippedname, precision, precision)
    end

    # Take a float containing an area in inch²
    # and convert it to a string representation according to the
    # model unit settings.
    #
    def format_to_readable_area(f2)
      if f2.nil?
        return nil
      end
      if model_unit_is_metric
        multiplier = 0.0254**2
        precision = [2, @length_precision].max
        unit_strippedname = UNIT_STRIPPEDNAME_METER_2
      else
        multiplier = 1 / 144.0
        precision = [2, @length_precision].max
        unit_strippedname = UNIT_STRIPPEDNAME_FEET_2
      end
      UnitUtils.format_readable(f2 * multiplier, unit_strippedname, precision, precision)
    end

    # Take a float containing a volume in inch³
    # and convert it to a string representation according to the
    # model unit settings and the material_type (for Board Foot).
    #
    def format_to_readable_volume(f3, material_type = nil)
      if f3.nil?
        return nil
      end
      if model_unit_is_metric
        multiplier = 0.0254**3
        precision = [2, @length_precision].max
        unit_strippedname = UNIT_STRIPPEDNAME_METER_3
      else
        if material_type == MaterialAttributes::TYPE_SOLID_WOOD
          multiplier = 1 / 144.0
          precision = [2, @length_precision].max
          unit_strippedname = UNIT_STRIPPEDNAME_BOARD_FEET
        else
          multiplier = 1 / 1728.0
          precision = [2, @length_precision].max
          unit_strippedname = UNIT_STRIPPEDNAME_FEET_3
        end
      end
      UnitUtils.format_readable(f3 * multiplier, unit_strippedname, precision, precision)
    end

    # -----

    # Take a Length object and returns is float representation
    # in current model unit.
    def length_to_model_unit_float(length)
      return nil unless length.is_a?(Length)
      case @length_unit
      when INCHES
        length.to_inch
      when FEET
        length.to_feet
      when YARD
        length.to_yard
      when MILLIMETER
        length.to_mm
      when CENTIMETER
        length.to_cm
      when METER
        length.to_m
      end
    end

    # Take a float value that represent a length in current
    # model unit and convert it to a Length object.
    def model_unit_float_to_length(f)
      return nil unless f.is_a?(Float)
      case @length_unit
      when INCHES
        f.to_l
      when FEET
        f.feet.to_l
      when YARD
        f.yard.to_l
      when MILLIMETER
        f.mm.to_l
      when CENTIMETER
        f.cm.to_l
      when METER
        f.m.to_l
      end
    end

  end
end
