#!/bin/bash
# set certbot_standalone_http_port
certbot_standalone_http_port="80"

certbot_mail_address="0x00@apa.sh"

certbot_nginx="false"
certbot_apache="false"

# set certbot_server url
certbot_dev_server="https://acme-staging-v02.api.letsencrypt.org/directory"
certbot_prod_server="https://acme-v02.api.letsencrypt.org/directory"
certbot_server="${certbot_dev_server}"

if [ "$certbot_nginx" = "true" ] && [ "$certbot_apache" = "true" ]
then
	echo -e "ERROR: certbot_nginx=true certbot_apache=true"
	echo -e "INFO: please choose one or set all false for standalone"
	exit 1
fi

certbot_print_help_function(){
	echo -e "USAGE: ./certbot.sh install (to update and install certbot)"
	echo -e "USAGE: ./certbot.sh hostname1(,hostname2) "
	echo -e "USAGE: ./certbot.sh delete hostname1 (to delete certs and hooks)"
	echo -e "USAGE: ./certbot.sh list (to list registered certs)"
	exit 0
}
if [[ $# -eq 0 ]]
then
    	certbot_print_help_function
elif [ $1 = "help" ]
then
	certbot_print_help_function
elif [ $1 = "install" ]
then
	# update apt
	apt update
	# install certbot
	apt install certbot -y
	if [ "$certbot_nginx" = "true" ]
	then
		apt install python-certbot-nginx -y
	elif [ "$certbot_apache" = "true" ]
	then
		apt install python-certbot-apache -y
	fi
	exit 0
elif [ $1 = "delete" ]
then
	# delete cert domain
	certbot delete --cert-name "$2"
	rm /etc/letsencrypt/renewal-hooks/pre/"$2".hook
	rm /etc/letsencrypt/renewal-hooks/post/"$2".hook
	rm /etc/letsencrypt/renewal-hooks/deploy/"$2".hook
	echo -e "PRE POST DEPLOY renewal-hooks deleted"
	exit 0
elif [ $1 = "list" ]
then
	# list certbot certificates
	certbot certificates
	exit 0
else
	certbot_print_help_function
fi

# set certbot_domains_list_input for $1
certbot_domains_list_input="$1"

if [ "$certbot_nginx" != "true" ] && [ "$certbot_apache" != "true" ]
then
	# set certbot_domain_primary_subject_cn from certbot_domains_list_input
	IFS=',' read -ra certbot_domains_array <<< "$certbot_domains_list_input"
	certbot_domain_primary_subject_cn="${certbot_domains_array[0]}"

	# add pre hook
	mkdir -p /etc/letsencrypt/renewal-hooks/pre/
	echo -e "#!/bin/bash \n" > /etc/letsencrypt/renewal-hooks/pre/"${certbot_domain_primary_subject_cn}".hook
	echo -e "/sbin/iptables -t filter -A INPUT -m tcp -p tcp --dport ${certbot_standalone_http_port} -j ACCEPT" \
		> /etc/letsencrypt/renewal-hooks/pre/"${certbot_domain_primary_subject_cn}".hook
	chmod +x /etc/letsencrypt/renewal-hooks/pre/"${certbot_domain_primary_subject_cn}".hook

	# add post hook
	mkdir -p /etc/letsencrypt/renewal-hooks/post/
	echo -e "#!/bin/bash \n" > /etc/letsencrypt/renewal-hooks/post/"${certbot_domain_primary_subject_cn}".hook
	echo -e "/sbin/iptables -t filter -D INPUT -m tcp -p tcp --dport ${certbot_standalone_http_port} -j ACCEPT" \
		> /etc/letsencrypt/renewal-hooks/post/"${certbot_domain_primary_subject_cn}".hook
	chmod +x /etc/letsencrypt/renewal-hooks/post/"${certbot_domain_primary_subject_cn}".hook

	# add deploy hook
	mkdir -p /etc/letsencrypt/renewal-hooks/deploy/
	echo -e "#!/bin/bash \n" > /etc/letsencrypt/renewal-hooks/deploy/"${certbot_domain_primary_subject_cn}".hook
	chmod +x /etc/letsencrypt/renewal-hooks/deploy/"${certbot_domain_primary_subject_cn}".hook
fi

if [ "$certbot_nginx" = "true" ]
then
	certbot certonly --nginx \
		--expand -d "${certbot_domains_list_input}" \
		--agree-tos -m "${certbot_mail_address}" --non-interactive \
		--server "${certbot_server}"
elif [ "$certbot_apache" = "true" ]
then
	certbot certonly --apache \
		--expand -d "${certbot_domains_list_input}" \
		--agree-tos -m "${certbot_mail_address}" --non-interactive \
		--server "${certbot_server}"
else
	certbot certonly --standalone \
		--preferred-challenges http \
		--http-01-port "${certbot_standalone_http_port}" \
		--expand -d "${certbot_domains_list_input}" \
		--agree-tos -m "${certbot_mail_address}" --non-interactive \
		--pre-hook /etc/letsencrypt/renewal-hooks/pre/"${certbot_domain_primary_subject_cn}".hook \
		--post-hook /etc/letsencrypt/renewal-hooks/post/"${certbot_domain_primary_subject_cn}".hook \
		--deploy-hook /etc/letsencrypt/renewal-hooks/deploy/"${certbot_domain_primary_subject_cn}".hook \
		--server "${certbot_server}"
fi

if [ "$certbot_nginx" != "true" ] && [ "$certbot_apache" != "true" ]
then
	echo -e "Please edit your hooks to match the need (PRE, POST and DEPLOY):"
	echo -e " - /etc/letsencrypt/renewal-hooks/pre/${certbot_domain_primary_subject_cn}.hook"
	echo -e " - /etc/letsencrypt/renewal-hooks/post/${certbot_domain_primary_subject_cn}.hook"
	echo -e " - /etc/letsencrypt/renewal-hooks/deploy/${certbot_domain_primary_subject_cn}.hook"
fi
