library(tidyverse)
library(lubridate)
library(sf)

df <- read_csv('./data/raw/Covid19Casos.zip')

# df <- df %>%
#         mutate(across(starts_with('fecha_'), ymd))

df <- df %>%
        filter(residencia_pais_nombre == 'Argentina') %>%
        mutate( 
                edad = case_when(
                        edad_años_meses == "Meses" ~ 0,
                        TRUE ~ edad),
                delay_diagnost = as.integer(fecha_diagnostico - fecha_apertura),
                link = paste(residencia_provincia_id, residencia_departamento_id, sep='')
                ) %>%
        filter(nchar(link) == 5) %>%
        select(id_evento_caso, link, residencia_provincia_nombre:residencia_departamento_nombre,
               sexo, edad,origen_financiamiento, delay_diagnost,
               fecha_apertura, sepi_apertura, fecha_inicio_sintomas, fecha_diagnostico, 
               fecha_internacion:fecha_fallecimiento,
               clasificacion:clasificacion_resumen)
        
        
inse <- st_read('./data/raw/inse_vs_radio.shp') %>%
        rename(link=IDDPTO,
               vuln_sanitaria=VULNERABIL,
               nse=NSE,
               ctro_salud=CENTRO_DE_,
               hospital=HOSPITAL,
               posta=POSTA_SANI,
               poblacion=RADIOS_POB,
               hogares=RADIOS_HOG) %>%
        mutate(ctro_salud=as.numeric(ctro_salud),
               hospital=as.numeric(hospital),
               posta=as.numeric(posta))

inse_agg <-inse %>%
        st_drop_geometry(.) %>%
        group_by(link) %>%
        summarise(
                pob_depto = sum(poblacion),
                hogares_depto = sum(hogares),
                vuln_sanit = mean(vuln_sanitaria),
                vuln_sanit_sd = sd(vuln_sanitaria, na.rm = TRUE),
                inse = mean(nse),
                inse_sd = sd(nse, na.rm = TRUE),
                dist_hosp = mean(hospital),
                dist_hosp_sd = sd(hospital, na.rm = TRUE),
                dist_ctro_salud = mean(ctro_salud),
                dist_ctro_salud_sd = sd(ctro_salud),
                dist_posta = mean(posta),
                dist_posta_sd = sd(posta),
        )


df <- df %>%
        left_join(inse_agg) %>%
        drop_na(inse)

write_rds(df, './data/proc/data_covid.rds')

df_agg <- df %>%
        group_by(link, residencia_provincia_nombre, residencia_departamento_nombre, 
                 fecha_apertura, sexo, edad, origen_financiamiento, clasificacion_resumen) %>%
        summarise(inse=mean(inse),
                  vuln_sanit = mean(vuln_sanit),
                  dist_hosp = mean(dist_hosp),
                  dist_ctro_salid = mean(dist_ctro_salud),
                  dist_posta = mean(dist_posta),
                  )


write_rds(df_agg, './data/proc/covid_agg.rds')


df_agg <- df %>%
        group_by(link, residencia_provincia_nombre, residencia_departamento_nombre, 
                 fecha_apertura, sexo, edad, origen_financiamiento, clasificacion_resumen) %>%
        summarise(inse=mean(inse),
                  vuln_sanit = mean(vuln_sanit),
                  dist_hosp = mean(dist_hosp),
                  dist_ctro_salid = mean(dist_ctro_salud),
                  dist_posta = mean(dist_posta),
        )


write_rds(df_agg, './data/proc/covid_agg.rds')




set.seed(1249)
sampled <- df %>%
        group_by(link) %>%
        sample_frac(0.10)

write_rds(sampled, './data/proc/sample_data_covid.rds')
