library(glue)
library(stringr)

setwd(
  "~/Documents/research/Papers/tilings-and-woven-patterns-for-multivariate-mapping"
)

svgs <- dir(pattern = "*\\.svg")
col <- str_count(svgs, c("(0[1236789])|(1[012456])")) > 0
svgs_colour <- svgs[which(col)]
svgs_grayscale <- svgs[which(!col)]

for (svg in svgs_colour[13]) {
  base <- strsplit(svg, ".", fixed = TRUE)[[1]][1]
  op <- glue("{base}.png")
  type <- "export-type:png"
  area <- "export-area-drawing"
  bg <- "export-background:white"
  dpi <- "export-dpi:600"
  color_mode <- "export-png-color-mode:RGB_8"
  op_file <- glue("export-filename:{op}")
  cmd <- glue(
    '/Applications/Inkscape.app/Contents/MacOS/inkscape --actions="{type};{area};{bg};{dpi};{color_mode};{op_file};export-do;" {svg}'
  )
  # print(cmd)
  system(cmd)
}

for (svg in svgs_grayscale[c(5)]) {
  base <- strsplit(svg, ".", fixed = TRUE)[[1]][1]
  op <- glue("{base}.png")
  type <- "export-type:png"
  area <- "export-area-drawing"
  bg <- "export-background:white"
  dpi <- "export-dpi:600"
  color_mode <- "export-png-color-mode:Gray_8"
  op_file <- glue("export-filename:{op}")
  cmd <- glue(
    '/Applications/Inkscape.app/Contents/MacOS/inkscape --actions="{type};{area};{bg};{dpi};{color_mode};{op_file};export-do;" {svg}'
  )
  system(cmd)
}

for (png in dir(pattern = ".*.png$")[c(18)]) {
  system(glue("/opt/homebrew/bin/mogrify {png} -fuzz 20% -trim"))
}

## NOTE THAT FIGS 3 19 20 need trimming to size using the GIMP
