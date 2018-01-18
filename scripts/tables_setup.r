# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
# GENDER PAY GAP
# 	set up tables for later use. Not all will be used for the first article
#
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# PACOTES ----
library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(rgdal)

# DADOS ----
rais <- read_csv2("../data/20180110_rais_vinculos_2016.csv",
                   progress = T)
rais2 <-
  rais %>%
  mutate(rem_med_nominal = as.numeric(rem_med_nominal)) %>%
  spread(key = sexo, value = rem_med_nominal) %>%
  mutate(
    rem_h = `1`,
    rem_m = `2`,
    gap = rem_h - rem_m) %>%
  select(-`1`, -`2`) %>%
  group_by(ano, cbo_2002, sb_clas_20, emp_em_3112, idade, faixa_etaria,
           horas_contr, faixa_hora_contrat,
           gr_instrucao_ou_escolaridade_apos_2005, municipio, nat_juridica,
           raca_cor, tamestab, temp_empr, tipo_adm, tp_vinculo) %>%
  summarise(rem_h = mean(rem_h, na.rm = T),
            rem_m = mean(rem_m, na.rm = T),
            gap = mean(gap, na.rm = T))

# ANÁLISES ---
# Gap por UF
gap_uf <-
  rais2 %>%
  mutate(uf = substr(municipio, 1, 2)) %>%
  group_by(uf) %>%
  summarise(rem_h = mean(rem_h, na.rm = T),
            rem_m = mean(rem_m, na.rm = T)) %>%
  mutate(gap = rem_h - rem_m,
         gap_porc = gap / rem_h) %>%
  filter(!is.na(gap_porc),
         !is.nan(gap_porc),
         !is.infinite(gap_porc))

# Gap por Grau de instrução
gap_educ <-
  rais2 %>%
  mutate(
    educ = ifelse(gr_instrucao_ou_escolaridade_apos_2005 %in% c(1, 4),
                  "Ens. Fund. Incompleto", NA),
    educ = ifelse(gr_instrucao_ou_escolaridade_apos_2005 %in% c(5, 6),
                  "Ens. Fund. Completo", educ),
    educ = ifelse(gr_instrucao_ou_escolaridade_apos_2005 %in% c(7, 8),
                  "Ens. Médio Completo", educ),
    educ = ifelse(gr_instrucao_ou_escolaridade_apos_2005 %in% c(9, 10, 11),
                  "Ens. Superior Completo", educ)
  ) %>%
  group_by(educ) %>%
  summarise(rem_h = mean(rem_h, na.rm = T),
            rem_m = mean(rem_m, na.rm = T)) %>%
  mutate(gap = rem_h - rem_m,
         gap_porc = gap / rem_h) %>%
  filter(!is.na(gap_porc),
         !is.nan(gap_porc),
         !is.infinite(gap_porc))

# Gap por Raça e Cor
gap_raca <-
  rais2 %>%
  mutate(
    raca = ifelse(raca_cor == 1,
                  "Indígena", NA),
    raca = ifelse(raca_cor == 2,
                  "Branca", raca),
    raca = ifelse(raca_cor == 4,
                  "Preta", raca),
    raca = ifelse(raca_cor == 6,
                  "Amarela", raca),
    raca = ifelse(raca_cor == 8,
                  "Parda", raca)
  ) %>%
  group_by(raca) %>%
  summarise(rem_h = mean(rem_h, na.rm = T),
            rem_m = mean(rem_m, na.rm = T)) %>%
  mutate(gap = rem_h - rem_m,
         gap_porc = gap / rem_h) %>%
  filter(!is.na(gap_porc),
         !is.nan(gap_porc),
         !is.infinite(gap_porc))

# Gap por faixa etária
gap_idade <-
  rais2 %>%
  mutate(
    etaria = ifelse(faixa_etaria == 1,
                    "10 a 14 anos", NA),
    etaria = ifelse(faixa_etaria == 2,
                    "15 a 17 anos", etaria),
    etaria = ifelse(faixa_etaria == 3,
                    "18 a 24 anos", etaria),
    etaria = ifelse(faixa_etaria == 4,
                    "25 a 29 anos", etaria),
    etaria = ifelse(faixa_etaria == 5,
                    "30 a 39 anos", etaria),
    etaria = ifelse(faixa_etaria == 6,
                    "40 a 49 anos", etaria),
    etaria = ifelse(faixa_etaria == 7,
                    "50 a 64 anos", etaria),
    etaria = ifelse(faixa_etaria == 8,
                    "65 anos ou mais", etaria)
  ) %>%
  group_by(etaria) %>%
  summarise(rem_h = mean(rem_h, na.rm = T),
            rem_m = mean(rem_m, na.rm = T)) %>%
  mutate(gap = rem_h - rem_m,
         gap_porc = gap / rem_h) %>%
  filter(!is.na(gap_porc),
         !is.nan(gap_porc),
         !is.infinite(gap_porc))

# gap do salario medio por grupo de idade
# aqui, o valor já é ponderado pela quantidade de pessoas no grupo
gap_idade2 <-
  rais2 %>%
  group_by(idade) %>%
  summarise(rem_h = mean(rem_h, na.rm = T),
            rem_m = mean(rem_m, na.rm = T)) %>%
  mutate(gap = rem_h - rem_m,
         gap_porc = gap / rem_h) %>%
  filter(!is.na(gap_porc),
         !is.nan(gap_porc),
         !is.infinite(gap_porc))

# shapes
shape <- readOGR("../shapes",
                 "BRUFE250GC_SIR")

sh_ftf <- fortify(shape)
sh_data <- shape@data
sh_data$id <- rownames(sh_data)

# gap por estado
sh_data <-
  sh_data %>%
  mutate(CD_GEOCUF = as.character(CD_GEOCUF)) %>%
  left_join(gap_uf, by = c("CD_GEOCUF" = "uf"))

sh_ftf <-
  sh_ftf %>%
  left_join(sh_data, by = "id")

# SALVA ----
save(
  rais, gap_educ, gap_idade, gap_idade2, gap_uf, gap_raca, sh_ftf,
  file = "../data/Tabelas e gráficos.rda")
