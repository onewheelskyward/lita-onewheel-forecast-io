module ForecastIo
  module ImgForecasts
    include Magick
    def img_rain_forecast(forecast)
      binding.pry
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
              title.tspan("Duck youuu |").styles(:text_anchor=>'end', :font_size=>20,
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
