defmodule Formplug do

  def init(default_opts) do
    IO.puts("starting up Formplug...")
    default_opts
  end


  def call(conn, _opts) do
    IO.puts("here again")
	IO.inspect conn.method
	IO.inspect conn.path_info
    route(conn.method, conn.path_info, conn)
  end



  #####################################
  # Stripe Purchase form for Charge
  #####################################

  def route("POST", ["form-payment", "purchase"], conn) do
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # part (i) - get form data
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~

    {:ok, body, _} = Plug.Conn.read_body(conn)
    body = body |> Plug.Conn.Query.decode()
    email = body["stripeEmail"]
    token = body["stripeToken"]
    amount=body["amount"]

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # part (ii) - save and respond
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~

    case Stripe.Customer.create(%{source: token, email: email}) do
      
      {:ok, %Stripe.Customer{id: stripe_cus_id}} ->

          case Stripe.Charge.create(%{customer: stripe_cus_id, amount: amount, description: "premium", currency: "usd"}) do
    		  {:ok, %Stripe.Charge{id: stripe_charge_id}} ->
    		        save_data(email, stripe_cus_id, stripe_charge_id, amount)
    		        conn
    		        |> Plug.Conn.send_resp( 200, "Thank You. Your payment is approved. We will send you a confirmation email shortly.")
    		  {:error, _} ->
    		        conn
    		        |> Plug.Conn.send_resp( 200, "Sorry, your payment is denied. Please try a different card or contact us for other payment options.")
           end

      {:error, _} ->
    		conn
    		|> Plug.Conn.send_resp( 200, "Sorry, your payment is denied. Please try a different card or contact us for other payment options.")
    end

  end




  #####################################
  # Stripe form for subscription
  # 
  # Metered plan, where you save the
  # credit card number
  #####################################

  def route("POST", ["form-payment", "subscribe"], conn) do

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # part (i) - get form data
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~

    {:ok, body, _} = Plug.Conn.read_body(conn)
    body = body |> Plug.Conn.Query.decode()
    email = body["stripeEmail"]
    token = body["stripeToken"]
    amount=body["amount"]

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # part (ii) - save and respond
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~

    stripe_prod_id = "prod_JZ0opU76v7LINq"
    stripe_price_id = "price_1IvsmqGlbTd7l4KBfhPqNtYb"

    case Stripe.Customer.create(%{source: token, email: email}) do
      
      {:ok, %Stripe.Customer{id: stripe_cus_id}} ->
          case Stripe.Subscription.create(%{customer: stripe_cus_id, items: [ %{price: stripe_price_id} ] } ) do

    	    {:ok, %Stripe.Subscription{items: %Stripe.List{data: [%Stripe.SubscriptionItem{id: stripe_sub_id}  ] }}} ->
                IO.inspect Stripe.SubscriptionItem.Usage.create(stripe_sub_id, %{quantity: 100, timestamp: 1622179968 })
    		conn
    		|> Plug.Conn.send_resp( 200, "Thank You. Your subscription is approved. We will send you a confirmation email shortly.")
    	     {:error, _} ->
    		conn
    		|> Plug.Conn.send_resp( 200, "Sorry, your payment is denied. Please try a different card or contact us for other payment options.")
           end

      {:error, _} ->
    		conn
    		|> Plug.Conn.send_resp( 200, "Sorry, your payment is denied. Please try a different card or contact us for other payment options.")
    end

  end




  #####################################
  # Stripe form for webhook
  #####################################

  def route("POST", ["form-payment", "webhook"], conn) do
    IO.inspect "inside webhook"

    IO.inspect conn

    signing_secret = System.get_env("STRIPE_SIGNING_SECRET")
    {:ok, body, _} = Plug.Conn.read_body(conn)
    [stripe_signature] = Plug.Conn.get_req_header(conn, "stripe-signature")
    # IO.inspect Stripe.Webhook.construct_event(body, stripe_signature, signing_secret)
    
    conn |> Plug.Conn.send_resp( 200, "Accepted")
  end



  #####################################
  # Stripe form for payment intent
  #####################################

  def route("GET", ["form-payment", "intent"], conn) do
    IO.inspect "here now"

    {:ok, setup_intent} = Stripe.SetupIntent.create(%{})

    IO.inspect setup_intent


    conn
    |> Plug.Conn.put_resp_content_type("text/html")
    |> Plug.Conn.send_resp(200, "<form method=POST action=\"/form-payment/subscribe\"> <input type=\"hidden\" name=\"amount\" value=\"65000\"> <script src=\"https://checkout.stripe.com/checkout.js\" class=\"stripe-button\" data-key=\"pk_live_fjff6jDr3j$v#F##F$\" data-amount=\"65000\" data-allow-remember-me=\"false\" data-billing-address=\"true\" data-zip-code=\"true\" data-locale=\"auto\"></script> </form>")


  end



  ############################
  # DEFAULT
  ############################

  def route(_method, _path, conn) do
	IO.inspect conn
    # this route is called if no other routes match
    conn |> Plug.Conn.send_resp(404, "Couldn't find that page, sorry!")
  end


  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~
  #  save form data
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~
  defp save_data(email, stripe_cus_id, stripe_charge_id, amount) do

    time = :os.system_time(:seconds) |> Integer.to_string()
    randnum = Enum.random(100..999) |> Integer.to_string()
    filename = "save_" <> time <> "_" <> randnum
    {:ok, file} = File.open("stripe-payments/" <> filename, [:append])
    IO.puts(file, email)
    IO.puts(file, stripe_cus_id)
    IO.puts(file, stripe_charge_id)
    IO.puts(file, amount)
    IO.puts(file, "\n")
    File.close(file)

  end

end

