class Betsy::ResponseListenerController < ApplicationController
  def etsy_response_listener
    Betsy.request_access_token(params)
    render plain: "Etsy Account Linked"
  end
end
