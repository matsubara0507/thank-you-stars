ESpec.start()

espec_hexpm_json = File.read!("test/fixture/json/espec_hexpm.json")
phoenix_hexpm_json = File.read!("test/fixture/json/phoenix_hexpm.json")
not_found_hexpm_json = File.read!("test/fixture/json/not_found_hexpm.json")

ESpec.configure fn(config) ->
  config.before fn ->
    {:shared,
      espec_hexpm_json: espec_hexpm_json,
      phoenix_hexpm_json: phoenix_hexpm_json,
      not_found_hexpm_json: not_found_hexpm_json}
  end
end
