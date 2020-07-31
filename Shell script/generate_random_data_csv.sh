#!/bin/bash
if [[ -z $1 ]]; then
        echo 'You must provide as first and only arg the number of lines generated'
else
        hexdump -v -e '200/1 "%02x""\n"' /dev/urandom |
        awk -v OFS=';' '
        NR == 1 { print "extraction_id", "code_riad", "code_riad_temp", "lei", "siren", "siren_fictif", "cib", "code_opc", "code_ot", "code_ncb", "code_amf", "code_org_int", "code_nis", "identifiant_rci", "identifiant_rna", "code_bic", "identifiant_etranger", "type_identifiant_etranger", "identifiant_head_office", "identifiant_immediate_parent", "identifiant_ultimate_parent", "date_debut_entite", "date_fin_entite", "denomination", "adresse_ligne1", "adresse_ligne2", "adresse_ligne3", "adresse_ligne4", "code_postal", "ville", "code_nuts", "pays", "forme_juridique", "code_secteur", "code_sous_secteur", "code_nace", "statut_procedure_judiciaire", "date_statut_procedure_judiciaire", "taille_entreprise", "date_taille_entreprise", "nombre_employes", "total_bilan", "chiffre_affaires", "norme_comptable_indiv", "actif" }
        { print substr($0,1,8),substr($0,9,2), substr($0,1,20), substr($0,9,2), substr($0,1,127), substr($0,1,8), substr($0,9,2), substr($0,1,106), substr($0,9,2), substr($0,1,50), substr($0,1,8), substr($0,9,2), substr($0,1,8), substr($0,9,2), substr($0,1,8), substr($0,9,2), substr($0,1,8), substr($0,9,2), substr($0,1,8), substr($0,9,2), substr($0,9,2), "01/01/2020", "01/01/2020", substr($0,1,8), substr($0,1,8), substr($0,9,2), substr($0,1,8), substr($0,9,2), substr($0,1,8), substr($0,9,2), substr($0,1,8), substr($0,1,8), substr($0,9,2), substr($0,1,8), substr($0,9,2), substr($0,1,8), substr($0,1,15), substr($0,9,2), substr($0,1,13), "01/01/2020", int(NR*32768*rand()), int(NR*32768*rand()), int(NR*32768*rand()), substr($0,1,20), substr($0,9,2) }' |
        head -n "$1" > random_values.csv
  fi


#./generate_csv.sh 100000

# hdfs dfs -put random_values.csv /user/hive