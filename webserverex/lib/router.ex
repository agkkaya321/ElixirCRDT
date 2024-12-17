defmodule Webserverex.Router do
  use Plug.Router

  plug Plug.Static,
    at: "/",
    from: {:webserverex, "priv/static"},
    gzip: false,
    only: ~w(css js media assets favicon.ico robots.txt)

  # Ajout du plug pour parser les requêtes avant le match
  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug :match
  plug :dispatch

  # Route POST pour /message, récupération des paramètres depuis le corps de la requête ou la query string
  post "/message" do
    signe = conn.params["signe"] || "inconnu"
    number = conn.params["number"] || "inconnu"
    product = conn.params["product"] || "inconnu"

    IO.inspect(%{signe: signe, number: number, product: product}, label: "Paramètres reçus")

    Webserverex.Application.send_message(signe, number, product)
    send_resp(conn, 200, "Message envoyé au superviseur")
  end

  # Route pour servir index.html pour le routage côté client
  get "/*path" do
    conn
    |> put_resp_content_type("text/html")
    |> send_file(200, "priv/static/index.html")
  end

  # Route par défaut pour les autres méthodes HTTP
  match _ do
    send_resp(conn, 404, "Page non trouvée")
  end
end
