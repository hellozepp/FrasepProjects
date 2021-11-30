/* MEMSIZE has been set to 10G in SPRE home/sasv9.cfg */
/* Used to overwrite default 2G limit and necessary for proc corr or other SAS9 compute with greater data size */

options cashost='frasepviya35smp.cloud.com' casport=5570 casdatalimit=ALL fullstimer;

cas casauto sessopts=(timeout=3600, metrics=true);
caslib _all_ assign;

%macro generate(n_rows=10, n_num_cols=1, n_char_cols=1, mindate='01jan2005'd, maxdate='30jun2009'd, outdata=test, seed=0);
	data &outdata;
		array nums[&n_num_cols];
		array chars[&n_char_cols] $30;
		char_length=8;
		temp="MIIDdTCCAl2gAwIBAgILBAAAAAABFUtaw5QwDQYJKoZIhvcNAQEFBQAwVzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNVBAsTB1Jvb3QgQ0ExGzAZBgNVBAMTEkdsb2JhbFNpZ24gUm9vdCBDQTAeFw05ODA5MDExMjAwMDBaFw0yODAxMjgxMjAwMDBaMFcxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMRAwDgYDVQQLEwdSb290IENBMRswGQYDVQQDExJHbG9iYWxTaWduIFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDaDuaZjc6j40+Kfvvxi4Mla+pIH/EqsLmVEQS98GPR4mdmzxzdzxtIK+6NiY6arymAZavpxy0Sy6scTHAHoT0KMM0VjU/43dSMUBUc71DuxC73/OlS8pF94G3VNTCOXkNz8kHp1Wrjsok6Vjk4bwY8iGlbKk3Fp1S4bInMm/k8yuX9ifUSPJJ4ltbcdG6TRGHRjcdGsnUOhugZitVtbNV4FpWi6cgKOOvyJBNPc1STE4U6G7weNLWLBYy5d4ux2x8gkasJU26Qzns3dLlwR5EiUWMWea6xrkEmCMgZK9FGqkjWZCrXgzT/LCrBbBlDSgeF59N89iFo7+ryUp9/k5DPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBRge2YaRQ2XyolQL30EzTSo//z9SzANBgkqhkiG9w0BAQUFAAOCAQEA1nPnfE920I2/7LqivjTFKDK1fPxsnCwrvQmeU79rXqoRSLblCKOzyj1hTdNGCbM+w6DjY1Ub8rrvrTnhQ7k4o+YviiY776BQVvnGCv04zcQLcFGUl5gE38NflNUVyRRBnMRddWQVDf9VMOyGj/8N7yy5Y0b2qvzfvGn9LhJIZJrglfCm7ymPAbEVtQwdpf5pLGkkeB6zpxxxYu7KyJesF12KwvhHhm4qxFYxldBniYUr+WymXUadDKqC5JlR3XC321Y9YeRq4VzW9v493kHMB65jUr9TU/Qr6cf9tveCX4XSQRjbgbMEHMUfpIBvFSDJ3gyICh3WZlXi/EjJKSZp4A==";
		range=&maxdate-&mindate+1;
		format range date date9.;

		do i=1 to &n_rows;
			do j=1 to &n_num_cols;
				nums[j]=ranuni(&seed);
			end;

			do j=1 to &n_char_cols;
				char_length=ceil(ranuni(&seed)*100);
				chars[j]=substr(temp, ceil(ranuni(&seed)*1100), char_length);
			end;
			date=&mindate + int(ranuni(&seed)*range);
			output;
		end;
		drop i j temp range char_length;
	run;
%mend generate;

%generate(n_rows=100000,n_num_cols=5,n_char_cols=5,outdata=casuser.test_corr,seed=0);

proc cas;
	table.droptable / caslib='public' name='test_corr_100K' quiet=true;
	table.droptable / caslib='public' name='test_corr' quiet=true;
    table.promote / caslib='casuser' name='test_corr' targetcaslib='public' target='test_corr' drop=true;
quit;

proc cas;
	table.tabledetails / caslib='public' name='test_corr';
quit;

data public.test_corr_100K(copies=0 promote=yes);
	set public.test_corr(obs=100000);
run;

proc corr data=public.test_corr (keep=nums1 nums2 nums3 nums4 nums5 nums6 nums7 nums8) spearman;
   var nums1 nums2 nums3 nums4 nums5 nums6 nums7 nums8;
   with nums1 nums2 nums3 nums4 nums5 nums6 nums7 nums8;
run;

proc corr data=public.test_corr (keep=nums1 nums2 nums3 ) spearman;
   var nums1 nums2 nums3 ;
   with nums1 nums2 nums3;
run;

/* 4 variables : 1 min 08s */
/* 2 variables : 28s */
/* 8 variables : 3 min */


/*
NOTE: PROCEDURE CORR used (Total process time):
      real time           5:38.93
      cpu time            4:36.55
*/

proc freqtab data=public.test_corr;
	tables nums1 * nums2 / chisq;
	output out=out_freqtab chisq;
	ods exclude all;
run;

/* 9 100 000 : 16,7 secondes */
/* 91 000 000 : 207 secondes */

cas casauto terminate;
