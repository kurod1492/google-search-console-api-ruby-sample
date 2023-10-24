# https://qiita.com/tauemo/items/a7eaf9222156622dcd0d

require 'google/apis/searchconsole_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'csv'

CREDENTIALS_PATH = 'credentials.json'
OAUTH_SCOPE = Google::Apis::SearchconsoleV1::AUTH_WEBMASTERS_READONLY
TOKEN_PATH = 'token.yaml'

client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
authorizer = Google::Auth::UserAuthorizer.new(client_id, OAUTH_SCOPE, token_store)
user_id = 'default'

credentials = authorizer.get_credentials(user_id)

if credentials.nil?
  url = authorizer.get_authorization_url(base_url: 'urn:ietf:wg:oauth:2.0:oob')

  puts 'Open the following URL in the browser and enter the resulting authorization code:'
  puts url
  code = gets
  credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: 'urn:ietf:wg:oauth:2.0:oob')
end

service = Google::Apis::SearchconsoleV1::SearchConsoleService.new
service.authorization = credentials

site_url = 'https://www.example.com/'
feed_path = 'https://www.example.com/sitemap.xml'
date = '2023-10-23'

request = Google::Apis::SearchconsoleV1::SearchAnalyticsQueryRequest.new
request.start_date = date
request.end_date = date
request.dimensions = ['query', 'page']
request.row_limit = 3000

CSV.open("result/query-#{date}.csv", 'w+') do |csv|
  csv << ["date", "keyword", "page", "impressions", "clicks", "ctr", "position"]
end

response = service.query_searchanalytic(site_url, request)

response.rows.each do |row|
  CSV.open("result/query-#{date}.csv", 'a+') do |csv|
    keyword = row.keys[0]
    page = row.keys[1]
    clicks = row.clicks
    ctr = row.ctr
    impressions = row.impressions
    position = row.position
    csv << [date, keyword, page, impressions, clicks, ctr, position]
  end
end
