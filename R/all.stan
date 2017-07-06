data{
  int<lower=1> K;     		                // number of countries
  int<lower=1> T; 				                // number of years
  int<lower=1> S; 				                // number of series
  int<lower=0> N;                         // total number of observations
  int<lower=0> N_b;                       // total number of observations with baseline
  int<lower=1, upper=K> kk[N]; 	          // country for observation n
  int<lower=1, upper=T> tt[N]; 	          // year for observation n
  int<lower=1, upper=K*T> kktt[N];        // country-year for observation n
  int<lower=1, upper=S> ss[N];            // series for observation n
  int<lower=1, upper=T> ktt[K*T]; 	      // year for country-year kt ("country-year-year")
  int<lower=1, upper=K> ktk[K*T]; 	      // country for country-year kt ("country-year-country")
  vector<lower=0, upper=1>[N] gini_m; 	    // measured gini for observation n
  vector<lower=0, upper=1>[N] gini_m_se;    // std error of measured gini for obs n
  vector<lower=0, upper=1>[N_b] gini_b;     // baseline gini for obs n
  vector<lower=0, upper=1>[N_b] gini_b_se;  // std error of baseline gini for obs n
}  
  
parameters {
  real<lower=0, upper=1> gini[K*T];       // SWIID gini estimate of baseline in country k at time t
  real<lower=0, upper=.1> sigma_gini[K]; 	// country variance parameter (see Linzer and Stanton 2012, 12)

  vector<lower=0, upper=1>[N] gini_t_raw;   // centered gini_t
  vector<lower=0>[S] rho_s_raw;             // centered rho_s
  vector<lower=0>[S] sigma_rho_s;           // scale for series ratios
  vector<lower=0>[S] sigma_s; 	            // series noise
}

transformed parameters {
  vector<lower=0, upper=1>[N] gini_t;       // unknown "true" gini for obs n given gini_m and gini_m_se
  vector<lower=0>[S] rho_s;                 // ratio of series s 

  gini_t = gini_m + gini_m_se .* gini_t_raw;    // decenter
  rho_s = 1 + rho_s_raw .* (sigma_rho_s * .4);  // decenter
}

model {
  gini_t_raw ~ normal(0, 1);
  rho_s_raw ~ normal(0, 1);
  sigma_rho_s ~ cauchy(0, 1);
  
  for (kt in 1:K*T) {
    if (ktt[kt] == 1) {             // if this country-year is the first year for a country
      gini[kt] ~ normal(.35, .1);   // give it a random draw from N(.35, .1)
    } else {                        // otherwise, give it
      gini[kt] ~ normal(gini[kt-1], sigma_gini[ktk[kt]]); // a random walk from previous year
    }
  }
  
  for (n in 1:N) {
    if (n <= N_b) {
      gini[kktt[n]] ~ normal(gini_b[n], gini_b_se[n]);              // use baseline series where observed
      gini_b[n] ~ normal(rho_s[ss[n]] * gini_t[n], sigma_s[ss[n]]); // estimate rho_s 
    } else {
      gini[kktt[n]] ~ normal(rho_s[ss[n]] * gini_t[n], sigma_s[ss[n]]); // estimate gini from rho_s
    }
  }
}