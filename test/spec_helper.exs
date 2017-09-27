ESpec.start()

espec_hexpm_html = File.read!("test/fixture/html/espec_hexpm.html")
phoenix_hexpm_html = File.read!("test/fixture/html/phoenix_hexpm.html")
not_found_hexpm_html = File.read!("test/fixture/html/not_found_hexpm.html")

ESpec.configure fn(config) ->
  config.before fn ->
    {:shared,
      espec_hexpm_html: espec_hexpm_html,
      phoenix_hexpm_html: phoenix_hexpm_html,
      not_found_hexpm_html: not_found_hexpm_html}
  end
end
