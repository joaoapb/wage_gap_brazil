#
# CREATES CHARTS AND TABLES
#

# PACKAGES ----
# devtools::install_github("yixuan/showtext")
library(dplyr)
library(pander)
library(ggplot2)
library(ggthemes)
library(extrafont)
library(reshape2)
library(tidyr)

# DATA ----
load("../data/Tabelas e gráficos.rda")

# CHART SET UP ----
# set up font parameters

big <- 16
med <- 12
sma <- 10

txt_col_dark <- rgb(80, 80, 80, maxColorValue = 255)
txt_col_meddark <- rgb(110, 110, 110, maxColorValue = 255)
txt_col_med <- rgb(140, 140, 140, maxColorValue = 255)
txt_col_medlight <- rgb(170, 170, 170, maxColorValue = 255)
txt_col_light <- rgb(200, 200, 200, maxColorValue = 255)

# prepara o tema para o gráfico
textos <- element_text(
  face = "plain",
  colour = txt_col_dark,
  margin = 0.1,
  size = med)

titulos <- element_text(
  face = "bold",
  colour = txt_col_med,
  margin = 0.1,
  size = big)

titulos_eixos <- element_text(
  face = "plain",
  colour = txt_col_meddark,
  margin = 0.1,
  size = med)

texto_eixos <- element_text(
  face = "plain",
  colour = txt_col_medlight,
  margin = 0.1,
  size = sma)

texto_legenda <- element_text(
  face = "plain",
  colour = txt_col_dark,
  margin = 0.1,
  size = sma)

texto_titulo_legenda <- element_text(
  face = "bold",
  colour = txt_col_dark,
  margin = 0.1,
  size = sma)

theme_1 <-
  theme(
    text = textos,
    title = titulos,
    aspect.ratio = 0.5,
    axis.title = titulos_eixos,
    axis.text = texto_eixos,
    axis.ticks = element_blank(),
    axis.line = element_line(
      colour = txt_col_light,
      size = 0.8,
      linetype = 1,
      lineend = "round"),
    legend.background = element_blank(),
    legend.text = texto_legenda,
    legend.title = texto_titulo_legenda,
    legend.box.background = element_blank(),
    panel.background = element_blank(),
    panel.border = element_blank(),
    panel.grid.major = element_line(
      colour = rgb(230, 230, 230, maxColorValue = 255),
      size = 0.3,
      linetype = 5,
      lineend = "round"),
    panel.grid.minor = element_blank(),
    plot.background = element_blank(),
    plot.margin = grid::unit(c(0,0,0,0), "mm")
  )

# TABLES ----
# Tabela da distribuição dos salários
percentis <- c(0.05,
               seq(0.1, 0.9, by = 0.1),
               0.95,0.99)
fmt_real <- scales::format_format(prefix = "R$ ",
                                  decimal.mark = ",",
                                  big.mark = ".",
                                  digits = 2)
tab1.df <-
  data.frame(
    "Homem" = quantile(rais2$`1`, probs = percentis),
    "Mulher" = quantile(rais2$`2`, probs = percentis)) %>%
  mutate(
    Percentil = row.names(.))

tab1 <- tab1.df %>%
  mutate(
    Homem = paste0("R$ ", fmt_real(Homem)),
    Mulher = paste0("R$ ", fmt_real(Mulher))) %>%
  select(Percentil, Homem, Mulher)

write.csv2(tab1, "2_aux/Tabela 1.csv", row.names = F)

# CHARTS ----
rais2 <-
  rais %>%
  group_by(cbo_2002, sb_clas_20, faixa_etaria, faixa_hora_contrat,
           gr_instrucao_ou_escolaridade_apos_2005, nat_juridica,
           tamestab, tipo_adm, tp_vinculo, sexo) %>%
  summarise(rem_med = mean(as.numeric(rem_med_nominal), na.rm = T)) %>%
  filter(rem_med > 0) %>%
  spread(key = sexo, value = rem_med) %>%
  mutate(gap = `1` - `2`,
         gap_porc = `1` / `2` - 1) %>%
  filter(!is.na(gap),
         !is.nan(gap))

# Wage distribution
p1 <-
  ggplot(data = rais2 %>% filter(`1` <= 10000, `2` <= 10000)) +
  geom_point(aes(x = `1`, y = `2`),
             size = 0.3) +
  geom_abline(intercept = 0, slope = 1,
              color = "white") +
  geom_curve(
    data = data.frame(),
    aes(x = c(1250, 2500, 3750, 5000, 6250, 7500, 8750, 10000),
        y = c(0, 0, 0, 0, 0, 0, 0, 0),
        xend = c(0, 0, 0, 0, 0, 0, 0, 0),
        yend = c(1250, 2500, 3750, 5000, 6250, 7500, 8750, 10000)),
    color = "white") +
  coord_equal() +
  scale_x_continuous(expand = c(0,0))

ggsave(filename = "../imgs/wage_distribution_pt.png",
       bg = "transparent",
       plot = p1  + labs(x = "Homem", y = "Mulher") + theme_1)

ggsave(filename = "../imgs/wage_distribution_en.png",
       bg = "transparent",
       plot = p1  + labs(x = "Man", y = "Woman") + theme_1)

# media dos gaps, por salario
rais3 <-
  rais %>%
  group_by(cbo_2002, sb_clas_20, faixa_etaria, faixa_hora_contrat,
           gr_instrucao_ou_escolaridade_apos_2005, nat_juridica,
           tamestab, tipo_adm, tp_vinculo, sexo) %>%
  summarise(rem_med = mean(as.numeric(rem_med_nominal), na.rm = T)) %>%
  filter(rem_med > 0) %>%
  spread(key = sexo, value = rem_med) %>%
  mutate(gap = `1` - `2`,
         gap_porc = `1` / `2` - 1) %>%
  filter(!is.na(gap),
         !is.nan(gap)) %>%
  left_join(
    rais %>%
      group_by(cbo_2002, sb_clas_20, faixa_etaria, faixa_hora_contrat,
               gr_instrucao_ou_escolaridade_apos_2005, nat_juridica,
               tamestab, tipo_adm, tp_vinculo) %>%
      summarise(rem_med_geral = mean(as.numeric(rem_med_nominal),
                                     na.rm = T)))
q1 <- quantile(rais3$gap_porc, 0.1)
q9 <- quantile(rais3$gap_porc, 0.9)

rais3 <-
  rais3 %>%
  filter(between(gap_porc, q1, q9)) %>%  # filtra outliers bizarros
  group_by(rem_med_geral) %>%
  summarise(gap_porc = mean(gap_porc, na.rm = T))

p2 <- ggplot(rais3) +
  geom_smooth(aes(x = rem_med_geral,
                  y = gap_porc)) +
  scale_y_continuous(labels = scales::percent)

p3 <- ggplot(rais3 %>% filter(rem_med_geral < 10000)) +
  geom_smooth(aes(x = rem_med_geral,
                  y = gap_porc),
              color = "#7355A6",
              fill = "#DAD2E6") +
  scale_y_continuous(labels = scales::percent, expand = c(0, 0.01)) +
  scale_x_continuous(labels = scales::dollar_format(prefix = "R$ ",
                                                    big.mark = "."),
                     expand = c(0, 500))

ggsave(filename = "../imgs/gap_porcentage_pt.png",
       bg = "transparent",
       plot = p3 + labs(x = "Remuneração Média",
                        y = "Diferença percentual") + theme_1)

ggsave(filename = "../imgs/gap_porcentage_en.png",
       bg = "transparent",
       plot = p3 + labs(x = "Average Income",
                        y = "Wage Gap as percentage") + theme_1)
# Wage trajectory
p4 <-
  ggplot(rais %>%
           filter(idade %in% c(15:65)) %>%
           group_by(idade, sexo) %>%
           summarise(rem = mean(as.numeric(rem_med_nominal), na.rm = T))) +
  geom_area(aes(x = idade, y = rem,
                fill = as.factor(sexo), group = sexo),
            position = position_nudge(),
            alpha = 0.3) +
  scale_y_continuous(labels = scales::dollar_format(prefix = "R$",
                                                    big.mark = ".",
                                                    decimal.mark = ","))

ggsave(filename = "../imgs/wage_trajectory_pt.png",
       bg = "transparent",
       plot = p4  + scale_fill_manual(name = "Sexo",
                                      labels = c("Homem", "Mulher"),
                                      values = c("#1C9AD8", "#810F7C"),
                                      guide = "legend") +
         labs(x = "Idade, em anos",
              y = "Remuneração Média") + theme_1)

ggsave(filename = "../imgs/wage_trajectory_en.png",
       bg = "transparent",
       plot = p4  + scale_fill_manual(name = "Sex",
                                      labels = c("Man", "Woman"),
                                      values = c("#1C9AD8", "#810F7C"),
                                      guide = "legend") +
         labs(x = "Age (Years)",
              y = "Average Income") + theme_1)

# Histogram of wage gap
p5 <- ggplot(rais3) +
  theme_1 +
  theme(axis.line.y = element_blank()) +
  geom_vline(xintercept = 0, colour = txt_col_light,
             size = 0.8, linetype = 1) +
  geom_histogram(aes(x = gap_porc), bins = 100, fill = "#7355A6") +
  scale_x_continuous(labels = scales::percent, expand = c(0, 0))

ggsave(filename = "../imgs/wage_gap_hist_pt.png",
       bg = "transparent",
       plot = p5 +
         labs(x = "Diferença entre salários (percentual)",
              y = "Frequência") + theme_1)

ggsave(filename = "../imgs/wage_gap_hist_en.png",
       bg = "transparent",
       plot = p5 +
         labs(x = "Wage gap (percent)",
              y = "Frequency") + theme_1)

# Geographic distribution of wage gap
map <-
  ggplot(sh_ftf) +
  geom_polygon(
    aes(x = long,
        y = lat,
        group = group,
        fill = gap_porc),
    alpha = 0.8,
    color = "white",
    size = 0.3) +
  scale_fill_continuous(labels = scales::percent,
                        name = "Gap",
                        low = "#DAD2E6",
                        high = "#7355A6") +
  theme_map() + coord_map() + theme(legend.background = element_blank())

ggsave(filename = "../imgs/map.png",
       bg = "transparent",
       plot = map)
