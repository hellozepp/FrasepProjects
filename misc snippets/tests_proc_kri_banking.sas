/* TESTS PROCEDURES FOR ECB KRI */


/*
Chi-square, Cramer's V : PROC FREQTAB (in Visual Statistics, CAS) compute chi-squares and Cramer's V for categorical data.
*/

proc freqtab data=public.test_corr;
	tables chars1 * chars2 / chisq;
	output out=out_freqtab chisq;
	ods exclude all;
run;


proc freq data=public.test_corr(keep=chars1 chars2) order=data;
   tables chars1 * chars2 / nocum chisq;
run;

/*
Spearman correlation and Kendall's tau-b for continuous data
PROC CORR (in BASE SAS, SPRE) 
*/

/*proc freqtab
PROC FREQ (in SAS/STAT, SPRE) and PROC FREQTAB (in Visual Statistics, CAS) compute chi-squares and Cramer's V for categorical data. For PROC FREQ, documentation is here: CHISQ option and Chi-Square Tests and Statistics. 
Tschuprow's T can be computed directly from the chi-square value.

Binomial tests and confidence limits 
PROC FREQ (and PROC FREQTAB). Documentation: BINOMIAL option and Binomial Proportion.
*/

/*
Wilcoxon-Mann-Whitney, Kruskal-Wallis, Kolmogorov-Smirnov
PROC NPAR1WAY (in SAS/STAT, SPRE).  
*/
proc npar1way wilcoxon correct=no data=public.test_corr(keep=chars1 nums1);
   class chars1;
   var nums1;
   exact wilcoxon;
run;

/*
Somers' D (Gini coefficient)
PROC LOGSELECT (in Visual Statistics, CAS) and PROC LOGISTIC (in SAS/STAT, SPRE).
See the subsection Association Statistics in the section "Model Fit and Assessment Statistics."

Also ANOVA (PROC ANOVA in SAS/STAT, SPRE) and t-test (PROC TTEST, SAS/STAT, SPRE)

Some information about MEMSIZE is here: MEMSIZE system option
*/