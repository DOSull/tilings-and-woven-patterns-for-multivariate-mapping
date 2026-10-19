library(glue)
library(stringr)
library(xml2)
library(dplyr)

setwd(
  "~/Documents/research/Papers/tilings-and-woven-patterns-for-multivariate-mapping/final/figures"
)

svgs <- dir(path = "svg-src", pattern = "*\\.svg")

# remove 'patch_1'
for (svg in svgs) {
  base <- strsplit(svg, ".", fixed = TRUE)[[1]][1]
  ip <- str_glue("svg-src/{svg}")
  op <- str_glue("stripped/{svg}")
  sel <- "select-by-id:patch_1"
  sel_all <- "select-all:all"
  op_file <- str_glue("export-filename:{op}")
  cmd <- str_glue(
    '/Applications/Inkscape.app/Contents/MacOS/inkscape --actions="{sel};copy;delete;{sel_all};page-fit-to-selection;{op_file};export-do;" {ip}'
  )
  # print(cmd)
  system(cmd)
}

# determine scale factors
widths <- c()
heights <- c()
for (svg in svgs) {
  str_w <- ((read_xml(str_glue("stripped/{svg}")) |> as_list())[["svg"]] |> attributes())$width
  pt_i <- str_locate(str_w, "p")[1] - 1
  widths <- c(widths, str_sub(str_w, 1, pt_i) |> as.double())
  str_h <- ((read_xml(str_glue("stripped/{svg}")) |> as_list())[["svg"]] |> attributes())$height
  pt_i <- str_locate(str_h, "p")[1] - 1
  heights <- c(heights, str_sub(str_h, 1, pt_i) |> as.double())
}

wh = data.frame(w = widths, h = heights) |> 
  mutate(w = w / 72, h = h / 72) |>
  mutate(scale_w = 7 / w, scale_h = 9 / h) |>
  mutate(scale = if_else(scale_w < scale_h, scale_w, scale_h))

for (i in seq_along(svgs)) {
  input <- str_glue("stripped/{svgs[i]}")
  scale <- wh$scale[i]
  output <- str_glue("rescaled/{svgs[i]}")
  cmd <- str_glue(
    '/Applications/Inkscape.app/Contents/MacOS/inkscape --actions="select-all:all;transform-scale:{scale};page-fit-to-selection;export-filename:{output};export-do;" {input}'
  )
  system(cmd)
}


for (svg in svgs) {
  base <- strsplit(svg, ".", fixed = TRUE)[[1]][1]
  ip <- str_glue("rescaled/{svg}")
  op <- str_glue("pngs/{base}.png")
  cmd <- str_glue(
    '/Applications/Inkscape.app/Contents/MacOS/inkscape --actions="export-type:png;export-area-drawing;export-background:white;export-dpi:600;export-png-color-mode:RGB_8;export-filename:{op};export-do;" {ip}'
  )
  # print(cmd)
  system(cmd)
}

for (svg in svgs) {
  base <- strsplit(svg, ".", fixed = TRUE)[[1]][1]
  png <- str_glue("pngs/{base}.png")
  cmd1 <- str_glue("/opt/homebrew/bin/magick mogrify -units PixelsPerInch -density 600 {png}")
  cmd2 <- str_glue("/opt/homebrew/bin/magick mogrify -compress lzw -format tiff {png}")
  cmd3 <- str_glue("mv pngs/{base}.tiff tifs/")
  # system(cmd1)
  system(cmd2)
  system(cmd3)
}


for (svg in svgs) {
  base <- strsplit(svg, ".", fixed = TRUE)[[1]][1]
  ip <- str_glue("rescaled/{svg}")
  op <- str_glue("eps/{base}.eps")
  cmd <- str_glue(
    '/Applications/Inkscape.app/Contents/MacOS/inkscape --actions="export-type:eps;export-area-drawing;export-background:white;export-filename:{op};export-do;" {ip}'
  )
  # print(cmd)
  system(cmd)
}
