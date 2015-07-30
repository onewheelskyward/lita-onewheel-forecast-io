module ForecastIo
  module Constants
    def scale
      'f'
    end

    def ansi_chars
      %w[_ ▁ ▃ ▅ ▇ █]   # Thx, agj #pdxtech
    end

    def ozone_chars
      %w[・ o O @ ◎ ◉]
    end

    def ascii_chars
      %w[_ . - ~ * ']
    end

    # Based on the chance of precipitation.
    def get_rain_range_colors
      { 0..0.10    => :blue,
        0.11..0.20 => :purple,
        0.21..0.30 => :teal,
        0.31..0.40 => :green,
        0.41..0.50 => :lime,
        0.51..0.60 => :aqua,
        0.61..0.70 => :yellow,
        0.71..0.80 => :orange,
        0.81..0.90 => :red,
        0.91..1    => :pink
      }
    end

    # Based on the precipIntensity field, tested mostly on Portland data.  YIMV.
    def get_rain_intensity_range_colors
      { 0..0.0050      => :blue,
        0.0051..0.0100 => :purple,
        0.0101..0.0130 => :teal,
        0.0131..0.0170 => :green,
        0.0171..0.0220 => :lime,
        0.0221..0.0280 => :aqua,
        0.0281..0.0330 => :yellow,
        0.0331..0.0380 => :orange,
        0.0381..0.0430 => :red,
        0.0431..1      => :pink
      }
    end

    # Based on the temp in F.
    def get_temp_range_colors
      # Absolute zero?  You never know.
      { -459.7..24.99 => :blue,
        25..31.99     => :purple,
        32..38        => :teal,
        38..45        => :green,
        45..55        => :lime,
        55..65        => :aqua,
        65..75        => :yellow,
        75..85        => :orange,
        85..95        => :red,
        95..99.999    => :pink,
        100..159.3    => :white
      }
    end

    # Based on the wind ground speed in mph.
    def get_wind_range_colors
      {   0..3    => :blue,
          3..6    => :purple,
          6..9    => :teal,
          9..12   => :aqua,
          12..15  => :yellow,
          15..18  => :orange,
          18..21  => :red,
          21..999 => :pink,
      }
    end

    # Based on the chance of sun.
    def get_sun_range_colors
      { 0..0.20    => :green,
        0.21..0.50 => :lime,
        0.51..0.70 => :orange,
        0.71..1    => :yellow
      }
    end

    # Based on the percentage of relative humidity.
    def get_humidity_range_colors
      {   0..0.12    => :blue,
          0.13..0.25 => :purple,
          0.26..0.38 => :teal,
          0.39..0.5  => :aqua,
          0.51..0.63 => :yellow,
          0.64..0.75 => :orange,
          0.76..0.88 => :red,
          0.89..1    => :pink,
      }
    end

    # IRC colors.
    def colors
      { :white  => '00',
        :black  => '01',
        :blue   => '02',
        :green  => '03',
        :red    => '04',
        :brown  => '05',
        :purple => '06',
        :orange => '07',
        :yellow => '08',
        :lime   => '09',
        :teal   => '10',
        :aqua   => '11',
        :royal  => '12',
        :pink   => '13',
        :grey   => '14',
        :silver => '15'
      }
    end

    # I have no use for these yet, and yet they're handy to know.
    # def attributes
    #   { :bold       => 2.chr,
    #     :underlined => 31.chr,
    #     :underline  => 31.chr,
    #     :reversed   => 22.chr,
    #     :reverse    => 22.chr,
    #     :italic     => 22.chr,
    #     :reset      => 15.chr,
    #   }
    # end

    # End constants

  end
end
