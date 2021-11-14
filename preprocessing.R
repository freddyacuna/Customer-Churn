install.packages(c("rio","readxl","dplyr","Hmisc","fastDummies","caret","rpart","randomForest","rpart.plot","themis","ROSE","kernlab","xgboost","glmnet","elasticnet","ggplot2"))
library(dplyr)
library(caret)
library(rpart)
library(randomForest)
library(rpart.plot)
library(themis)
library(ROSE)
library(kernlab)
library(xgboost)
library(glmnet)
library(elasticnet)
library(ggplot2)


df <- rio::import('https://github.com/freddyacuna/Customer-Churn/raw/main/data/Base_Fuga_2021.xlsx')
df[4426,7] <- NA #ID- 4426 : Ingreso de -975950 MICE 866700


df_factor <- df %>% dplyr::mutate(NivelEduc =factor(NivelEduc, levels=c("EST_UNI", "MED", "TEC", "UNI"), 
                                                    labels = c("Estudiante","Media","Tecnica","Universitaria")
),
Telefono = factor(Telefono, level=c("SI"), 
                  labels = c("Si")
),
Genero = factor(Genero, level =c("F","H","M"), 
                labels=c("Femenino","Masculino","Masculino") 
),
EstCivil = factor(EstCivil, level =c("CAS","DIV","SOL","VIU"), 
                  labels=c("Casado","Divorciado","Soltero","Viudo") 
),
Region = factor(Region, 
                level =c("RM"),
                labels=c("RM") 
),
FUGA = factor(FUGA, 
              level =c("NF","F"), 
              labels=c("NoFuga", "Fuga")
),
ID= dplyr::row_number()
) %>%
  dplyr::rename(Credit_T = "CreditMes_T", Credit_T1="CreditMes_T-1", Credit_T2="CreditMes_T-2",
                Numcredit_T = "NumTarjCred_T", Numcredit_T1 = "NumTarjCred_T-1", Numcredit_T2 = "NumTarjCred_T-2",
                Numweb_T ="NumTransWeb_T", Numweb_T1 ="NumTransWeb_T-1", Numweb_T2 ="NumTransWeb_T-2",
                Margen_T = "MargenComp_T", Margen_T1 = "MargenComp_T-1",  Margen_T2 = "MargenComp_T-2",  Margen_T3 = "MargenComp_T-3",                                 
                Margen_T4 = "MargenComp_T-4", Margen_T5 = "MargenComp_T-5",  Margen_T6 = "MargenComp_T-6"
  )


##### REEMPLZA -------------------------------------------------------------

df_factor[842	,c('Credit_T')] <- 639500
df_factor[3515,c('Credit_T')] <- 720050

df_factor[143	,c('Numcredit_T')] <- 0
df_factor[604 ,c('Numcredit_T')] <- 1
df_factor[1237,c('Numcredit_T')] <- 1
df_factor[2253,c('Numcredit_T')] <- 0
df_factor[2807,c('Numcredit_T')] <- 1
df_factor[3296,c('Numcredit_T')] <- 0
df_factor[3465,c('Numcredit_T')] <- 2


df_factor[3576	,c('Numcredit_T1')] <- 0
df_factor[3901 ,c('Numcredit_T1')] <- 1



df_factor[3290	,c('Numweb_T')] <- 0
df_factor[3614	,c('Numweb_T')] <- 13

df_factor[2969	,c('Numweb_T1')] <- 0
df_factor[3836	,c('Numweb_T1')] <- 1


df_factor[3291	,c('Margen_T')] <- 227765.6
df_factor[3659	,c('Margen_T')] <- 226734.1

df_factor[4075	,c('Margen_T1')] <- 196429.2

df_factor[3699	,c('Margen_T4')] <- 241536.3
df_factor[5571	,c('Margen_T4')] <- 241730.3

df_factor[3077	,c('Margen_T5')] <- 224639.5

df_factor[4426, c('Ingreso')] <- 866700 #ID- 4426 : Ingreso de -975950 MICE 866700


df_factor[159	,c('NivelEduc')] <- 'Universitaria'
df_factor[386,c('NivelEduc')] <- 'Universitaria'
df_factor[3936,c('NivelEduc')] <- 'Tecnica'


df_factor[570,c('EstCivil')] <- 'Soltero'
df_factor[4451,c('EstCivil')] <- 'Casado'

## Tratamiento Outliers ---------------------------------------------------------



capOutlier <- function(x){
  if(class(x)=="numeric"){
    qnt <- quantile(x, probs=c(.25, .75), na.rm = T)
    caps <- quantile(x, probs=c(.05, .95), na.rm = T)
    H <- 1.5 * IQR(x, na.rm = T)
    x[x < (qnt[1] - H)] <- caps[1]# (qnt[1] - H) #caps[1]#
    x[x > (qnt[2] + H)] <- caps[2]# (qnt[2] + H) 
    return(x)
  }else{ return(x) }
}


df_replace <- sapply(df_factor,capOutlier)


df_replace <- as_tibble(df_replace) %>% 
  dplyr::select(-c(Telefono, NivelEduc, Genero, EstCivil, Region, FUGA)) %>% 
  dplyr::inner_join(df_factor %>% 
                      dplyr::select(c(Telefono, NivelEduc, Genero, 
                                      EstCivil, Region, FUGA,ID)), by = "ID")

outliers <- function(x) {
  
  Q1 <- quantile(x, probs=.25)
  Q3 <- quantile(x, probs=.75)
  iqr = Q3-Q1
  
  q_superior = Q3 + (iqr*1.5)
  q_inferior = Q1 - (iqr*1.5)
  
  x > q_superior | x < q_inferior
  
}

remove_outliers <- function(df, cols = names(df)) {
  for (col in cols) {
    df <- df[!outliers(df[[col]]),]
  }
  df
}


df_remove_1.5 <-remove_outliers(df_factor, c('Credit_T','Credit_T1','Credit_T2',
                                             'Numcredit_T','Numcredit_T1','Numcredit_T2',
                                             'Ingreso','Edad',
                                             'Numweb_T','Numweb_T1','Numweb_T2',
                                             'Margen_T','Margen_T1','Margen_T2','Margen_T3',
                                             'Margen_T4','Margen_T5','Margen_T6'))
outliers <- function(x) {
  
  Q1 <- quantile(x, probs=.25)
  Q3 <- quantile(x, probs=.75)
  iqr = Q3-Q1
  
  q_superior = Q3 + (iqr*3)
  q_inferior = Q1 - (iqr*3)
  
  x > q_superior | x < q_inferior
  
}

df_remove_3 <-remove_outliers(df_factor, c('Credit_T','Credit_T1','Credit_T2',
                                           'Numcredit_T','Numcredit_T1','Numcredit_T2',
                                           'Ingreso','Edad',
                                           'Numweb_T','Numweb_T1','Numweb_T2',
                                           'Margen_T','Margen_T1','Margen_T2','Margen_T3',
                                           'Margen_T4','Margen_T5','Margen_T6'))


## Resumen de base contruidas ---------------------------------------------------------

#df_factor # base considerando outlier n=5605
#df_replace # base considerando un reemplazo con los outlier 1.5 *IQR con n =5605
#df_remove_1.5 # base eliminando outlier 1.5 con n=1620
#df_remove_3 # base eliminando outlier 3 con n=3247


## Transformación y Creación ---------------------------------------------------------

df_replace2 <- df_replace %>% dplyr::mutate(card_T = factor(Numcredit_T, levels=c(0,1,2), 
                                                            labels = c("Ninguna","1 tarjeta","2 o más tarjetas")),
                                            
                                            card_T1 = factor(Numcredit_T1, levels=c(0,1,2), 
                                                             labels = c("Ninguna","1 tarjeta","2 o más tarjetas")),
                                            
                                            card_T2 = factor(Numcredit_T2, levels=c(0,1,2), 
                                                             labels = c("Ninguna","1 tarjeta","2 o más tarjetas")),
                                            
                                           
                                            
                                            web_T = Hmisc::cut2(Numweb_T, g=3),
                                            web_T1 = Hmisc::cut2(Numweb_T1, g=3),
                                            web_T2 = Hmisc::cut2(Numweb_T2, g=3),
                                            
                                            log_ingreso = log10(Ingreso),
                                            
                                            rate_ingres_credit = Ingreso/Credit_T, #Ratio ingreso/crédito
                                            
                                            log_credit_T  = log10(Credit_T),
                                            log_credit_T1 = log10(Credit_T1),
                                            log_credit_T2 = log10(Credit_T2),
                                            
                                            log_margen_T  = log10(Margen_T),
                                            log_margen_T1 = log10(Margen_T1),
                                            log_margen_T2 = log10(Margen_T2),
                                            log_margen_T3 = log10(Margen_T3), 
                                            log_margen_T4 = log10(Margen_T4),
                                            log_margen_T5 = log10(Margen_T5),
                                            log_margen_T6 = log10(Margen_T6),
                                            
                                            return_credit_T  = log_credit_T- log_credit_T1,
                                            return_credit_T1 = log_credit_T1- log_credit_T2,
                                            
                                            var_credit_T = (Credit_T- Credit_T1)/Credit_T1,
                                            var_credit_T1 = (Credit_T1- Credit_T2)/Credit_T2,                          
                                            
                                            var_margen_T  = (Margen_T-Margen_T1)/Margen_T1,
                                            var_margen_T1 = (Margen_T1-Margen_T2)/Margen_T2,
                                            var_margen_T2 = (Margen_T2-Margen_T3)/Margen_T3,
                                            var_margen_T3 = (Margen_T3-Margen_T4)/Margen_T4,
                                            var_margen_T4 = (Margen_T4-Margen_T5)/Margen_T5,
                                            var_margen_T5 = (Margen_T5-Margen_T6)/Margen_T6,
                                    
                                            
                                            
) %>% dplyr::select(-c(Credit_T,Credit_T1,Credit_T2,
                Numcredit_T,Numcredit_T1,Numcredit_T2,
                Numweb_T, Numweb_T1, Numweb_T2,
                Margen_T, Margen_T1, Margen_T2,
                Margen_T3, Margen_T4, Margen_T5,
                Margen_T6, Ingreso, Margen_T2,
                Telefono, Region))

data_Xnum <- df_replace2 %>% select(-c(ID,Genero, NivelEduc,EstCivil,FUGA,
                                            card_T,card_T1,card_T2,
                                            web_T,web_T1,web_T2))

data_Xfactor <- df_replace2 %>% select(c( Genero, NivelEduc,EstCivil,
                                            card_T,card_T1,card_T2,
                                            web_T,web_T1,web_T2))

data_Xdummy <- fastDummies::dummy_cols(data_Xfactor,  remove_most_frequent_dummy = TRUE) %>% 
                                    select(-c( Genero, NivelEduc,EstCivil,
                                            card_T,card_T1,card_T2,
                                            web_T,web_T1,web_T2))

df_X <- cbind(data_Xdummy,data_Xnum)

df_Y <- df_replace2 %>% select(FUGA) 
#df_Y <-df_Y %>% mutate(Fuga=if_else( as.character(FUGA) == "No Fuga","NF","F") )

preProcValues<- preProcess(df_X, method = c("range"))
df_X <- predict(preProcValues, df_X)

data_set <- cbind(df_X,df_Y)
