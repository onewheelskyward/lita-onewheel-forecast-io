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

      x_offset = (area[:x] - graph_area[:x]) / 2
      y_offset = ((area[:y] - graph_area[:y]) / 2) + ((area[:y] - graph_area[:y]) / 6)
      title_y = (area[:y] - graph_area[:y]) / 6
      title_text_y = title_y * 0.90
      title_text_y_offset  = title_y * 0.10

      scale_x_area = [0, x_offset]
      scale_y_area = [(y_offset + graph_area[:y]), area[:y]]

      RVG::dpi = 72

      rain_points = percip_chance_to_points(data, key, 0, 1, graph_area)
      scale_lines = plot_scale_lines(data, key, 0, 1, graph_area, 20, 10)

      rvg = RVG.new(area[:x].px, area[:y].px).viewbox(0,0,area[:x],area[:y]) do |canvas|
        canvas.background_fill = 'white'

        rain = RVG::Group.new do |_rain|
          _rain.path(rain_points).styles(:stroke_width=>1, :fill=>'blue', :stroke=>'grey')
        end

        lines_x = RVG::Group.new do |_sx|
          scale_lines[:x].each do |sx|
            _sx.line(sx[:data][0], sx[:data][1], sx[:data][2], sx[:data][3]).styles(:stroke_width=>1, :stroke=>sx[:color])
          end
        end

        lines_y = RVG::Group.new do |_sy|
          scale_lines[:y].each do |sy|
           _sy.line(sy[:data][0], sy[:data][1], sy[:data][2], sy[:data][3]).styles(:stroke_width=>1, :stroke=>sy[:color])
           end
        end

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
