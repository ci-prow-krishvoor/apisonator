module ThreeScale
  module Backend
    module Validators
      class Referrer < Base
        BYPASS = '*'

        def apply
          if service.referrer_filters_required? && application.has_referrer_filters?
            if application.referrer_filters.any? { |filter| matches?(filter, params[:referrer]) }
              succeed!
            else
              fail!(ReferrerNotAllowed.new(params[:referrer]))
            end
          else
            succeed!
          end
        end

        private

        def matches?(pattern, value)
          if value == BYPASS
            true
          else
            pattern = Regexp.quote(pattern)
            pattern = pattern.gsub('\*', '.*')

            /#{pattern}/ =~ value
          end
        end
      end
    end
  end
end
