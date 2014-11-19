module Lita
  module Handlers
    class ForecastIo < Handler
      route(/^!rain/, :is_it_raining)

      def is_it_raining(response)
        response.reply 'no'
      end
    end

    Lita.register_handler(ForecastIo)
  end
end
