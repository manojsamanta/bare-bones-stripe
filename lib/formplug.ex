defmodule Formplug do
  def init(default_opts) do
    IO.puts("starting up Formplug...")
    default_opts
  end

  def call(conn, _opts) do
    IO.puts("here again")
    route(conn.method, conn.path_info, conn)
  end

  #####################################
  # Stripe Purchase form
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
