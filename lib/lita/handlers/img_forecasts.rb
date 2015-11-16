module ForecastIo
  module ImgForecasts
    include Magick
    def img_rain_forecast(forecast, location)
      if forecast['minutely'].nil?
        return 'No minute-by-minute data available.'
      end

      data = forecast['minutely']['data']
      key = 'precipProbability'

      area = {x: 740, y: 500}
      graph_area = {x: 600, y: 300}

      # Graph area offset 
      # (for graph-related group placement within RVG)
      x_offset = (area[:x] - graph_area[:x]) / 2
      y_offset = ((area[:y] - graph_area[:y]) / 2) + ((area[:y] - graph_area[:y]) / 6)

      # Title stuffs
      title_text = "Rain Forecast for"
      title_location = location.location_name
      title_y = y_offset / 2
      title_x = (area[:x] / 2) - x_offset
      title_text_size = ((area[:y] - graph_area[:y]) / 6) * 0.90

      # Graph scale/annotation stuff
      line_max_length = 20
      scale_text_size = 10
      # scale_x_area = [0, x_offset]
      # scale_y_area = [(y_offset + graph_area[:y]), area[:y]]
      scale_y_x = x_offset / 2
      scale_y_y = (area[:y] / 2) - y_offset
      scale_x_x = title_x
      scale_x_y = (area[:y] - (y_offset + graph_area[:y])) + (scale_text_size * 2)
      scale_x_title = "Minutes"
      scale_x_subtitle = "(0-60)"
      scale_y_title = "Precipitation Chance"
      scale_y_subtitle = "(0-100%)"

      RVG::dpi = 72

      rain_points = percip_chance_to_points(data, key, 0, 1, graph_area)
      scale_lines = plot_scale_lines(data, key, 0, 1, graph_area, line_max_length, 10)

      rvg = RVG.new(area[:x].px, area[:y].px).viewbox(0,0,area[:x],area[:y]) do |canvas|
        canvas.background_fill = 'white'

        canvas.text(title_x, title_y) do |title|
            title.tspan("#{title_text} | ").styles(:text_anchor=>'end', :font_size=>title_text_size,
                                                   :font_family=>'helvetica', :fill=>'black')
            title.tspan("#{title_location}").styles(:font_size=>title_text_size, :font_family=>'helvetica',
                                                    :font_style=>'italic', :fill=>'red')
        end

        canvas.text(scale_x_x, scale_x_y) do |x_title|
          x_title.tspan("#{scale_x_title} ").styles(:text_anchor=>'end', :font_size=>scale_text_size,
                                                  :font_family=>'helvetica', :fill=>'black')
          x_title.tspan("#{scale_x_subtitle}").styles(:font_size=>scale_text_size, :font_family=>'helvetica',
                                                    :font_style=>'italic', :fill=>'grey')
        end

        canvas.text(scale_y_x, scale_y_y).styles(:writing_mode=>'tb', :glyph_orientation_vertical=>90) do |y_title|
          y_title.tspan("#{scale_y_title} ").styles(:text_anchor=>'end', :font_size=>scale_text_size,
                                                  :font_family=>'helvetica', :fill=>'black')
          y_title.tspan("#{scale_y_subtitle}").styles(:font_size=>scale_text_size, :font_family=>'helvetica',
                                                    :font_style=>'italic', :fill=>'grey')
        end

        # Draft precip chance chart
        rain = RVG::Group.new do |_rain|
          _rain.path(rain_points).styles(:stroke_width=>1, :fill=>'blue', :stroke=>'grey')
        end

        # Draft X axis scale lines
        lines_x = RVG::Group.new do |_sx|
          scale_lines[:x].each do |sx|
            _sx.line(sx[:data][0], sx[:data][1], sx[:data][2], sx[:data][3]).styles(:stroke_width=>1, :stroke=>sx[:color])
          end
        end

        # Draft Y axis scale lines
        lines_y = RVG::Group.new do |_sy|
          scale_lines[:y].each do |sy|
           _sy.line(sy[:data][0], sy[:data][1], sy[:data][2], sy[:data][3]).styles(:stroke_width=>1, :stroke=>sy[:color])
           end
        end

        # Layer groups onto canvas; bottom -> top
        canvas.use(lines_x).translate(x_offset, y_offset)
        canvas.use(lines_y).translate(x_offset, y_offset)
        canvas.use(rain).translate(x_offset, y_offset)
      end

      rvg.draw.write('rain.gif')

    end

    def duck_you(duck_subject)

       RVG::dpi = 72

       rvg = RVG.new(2.5.in, 2.5.in).viewbox(0,0,250,250) do |canvas|
           canvas.background_fill = 'white'

           canvas.g.translate(100, 150).rotate(-30) do |body|
              body.styles(:fill=>'yellow', :stroke=>'black', :stroke_width=>2)
              body.ellipse(50, 30)
              body.rect(45, 20, -20, -10).skewX(-35)
          end

          canvas.g.translate(130, 83) do |head|
              head.styles(:stroke=>'black', :stroke_width=>2)
              head.circle(30).styles(:fill=>'yellow')
              head.circle(5, 10, -5).styles(:fill=>'black')
              head.polygon(30,0, 70,5, 30,10, 62,25, 23,20).styles(:fill=>'orange')
          end

          foot = RVG::Group.new do |_foot|
              _foot.path('m0,0 v30 l30,10 l5,-10, l-5,-10 l-30,10z').
                    styles(:stroke_width=>2, :fill=>'orange', :stroke=>'black')
          end
          canvas.use(foot).translate(75, 188).rotate(15)
          canvas.use(foot).translate(100, 185).rotate(-15)

          canvas.text(125, 30) do |title|
              title.tspan("Duck youuu | ").styles(:text_anchor=>'end', :font_size=>20,
                             :font_family=>'helvetica', :fill=>'black')
              title.tspan("#{duck_subject}").styles(:font_size=>22,
                     :font_family=>'times', :font_style=>'italic', :fill=>'red')
          end
          canvas.rect(249,249).styles(:stroke=>'blue', :fill=>'none')
      end

      rvg.draw.write('duck.gif')

    end

  end
end
