# certbot.sh

curl --url https://raw.githubusercontent.com/panpansh/certbot.sh/master/certbot.sh --output ~/certbot.sh
chmod +x ~/certbot.sh

change certbot.sh to match your needs : 
```bash
certbot_mail_address=""
# note: for standalone set certbot_nginx and certbot_apache var to false
certbot_nginx="false"
certbot_apache="false"
# First start with the dev api of letsencrypt (default value)
# When you get congratulations from letsencrypt you can start using prod servers
certbot_server="${certbot_prod_server}"
```
