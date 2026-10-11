# Classification of DHS answer labels for the recode covariates (labels lower-cased and trimmed; rdhs keeps labels,
# not codes). Ported unchanged from the analysis project (R_cbh/snow_units/label_rules.R); built from the label inventory of the 98 v9 DHS surveys (06_label_inventory.R). Every non-blank label
# must be classified: an unknown label stops. Blank ("") = item not asked of that row -> NA (outside the denominator).
# "missing" stays in the denominator as "no", as in the DHS tables and 17_recode_replacements.R.
snow_unclassified <- function(x, out, what) {
  bad <- unique(x[!is.na(x) & nzchar(x) & is.na(out)])
  if (length(bad)) stop(what, ": unclassified labels: ", paste(head(bad, 20), collapse = " | "), call. = FALSE)
}

# Vaccination doses (h3, h5, h7, h9): card date, marked on card or mother's report = given.
snow_vacc <- function(x) {
  yes <- c("vaccination date on card", "vacc. date on card", "vaccination marked on card", "vacc. marked on card", "reported by mother")
  no <- c("no", "don't know", "dk", "missing")
  out <- ifelse(x %in% yes, 1, ifelse(x %in% no, 0, NA_real_)); snow_unclassified(x, out, "vaccination"); out
}

# Place of delivery (m15): any public, private or NGO medical facility = 1; home, traditional birth attendant,
# on the way, abroad, pharmacy/drug vendor, other, missing = 0. Unlabelled numeric codes follow the DHS scheme
# (1x home, 2x public, 3x private sector).
snow_facility <- function(x) {
  way <- "on the way|enroute|en route|^abroad$"
  strong <- paste0("hospital|hosptial|\\bhosp\\b|health cent|health post|health hut|health cabin|health home|health clinic|",
    "health station|health facility|health care|clinic|maternity|dispensary|case de sant|cscom|csref|csps|\\bcsi\\b|\\bcms\\b|",
    "polyclinic|medical|chps|\\bchu\\b|\\bchr\\b|\\bpmi\\b|nursing|^cs govt|outreach|community health|mother and child health|",
    "cabinet|infirmary")
  non <- "home|house|residence|\\btba\\b|traditional|^other$|^missing$|pharmacy|ppmv|patent and proprietary"
  generic <- "public|private|government|govt|\\bgov\\.|\\bngo\\b|sector|mission|religious|faith|confession|\\bfbo\\b|cham|doctor|centre|center|\\bpost\\b"
  # Survey-specific labels (<= 6 births each): BLM = Banja La Mtsogolo clinics (MW7AFL) and the public mobile
  # brigade (MZ41FL) are facilities; a health worker's, nurse's or community distributor's home is not.
  facility_named <- c("blm", "mobile brigade")
  home_named <- c("health worker", "midwife/nurse", "nurse", "cbd worker")
  code <- suppressWarnings(as.integer(ifelse(grepl("^[0-9]+$", x), x, NA)))
  out <- ifelse(!is.na(code), as.numeric(code >= 20 & code < 40), NA_real_)
  out[x %in% facility_named] <- 1; out[x %in% home_named] <- 0
  out[is.na(out) & grepl(way, x)] <- 0
  out[is.na(out) & grepl(strong, x)] <- 1
  out[is.na(out) & grepl(non, x)] <- 0
  out[is.na(out) & grepl(generic, x)] <- 1
  snow_unclassified(x, out, "place of delivery"); out
}

# Drinking-water source (hv201), JMP 2017 ladder as in current DHS tables: piped, borehole/tube well, protected
# well or spring, rainwater, tanker/cart/vendor-delivered, kiosk, bottled and sachet water are improved.
# Older surveys' location-only piped categories (Cameroon 2004, Mozambique 2003) are piped. Two labels carry no
# protection/type information and are set by argument, chosen against the published national values:
# "spring" (default unimproved) and "water vendor" (default improved, delivered water).
snow_water <- function(x, spring = 0, vendor = 1) {
  unimp <- paste0("unprotected|non protected|non-protected|not protected|not improved|open public well|open well|river|stream|",
    "lake|pond|\\bdam\\b|\\bsea\\b|surface|canal|irrigation|channel|^other$|^missing$|^99$")
  imp <- paste0("pip|tap|standpipe|fountain|borehole|bore hole|tube well|forage|protected|covered|improved spring|rain|bottle|",
    "sachet|\\bbag\\b|water bag|bag water|tanker|tank|cart|kiosk|vendor|gravity|public water|station|well with pump|inside|",
    "in the house|courtyard|of a neighbor|along the road|in own land|neighbor's land|neighbor's house|jerrycan|motorcycle|",
    "bicycle|large bottle|mineral water|domestic points")
  out <- rep(NA_real_, length(x))
  out[x == "spring"] <- spring; out[x == "water vendor"] <- vendor
  out[is.na(out) & grepl(unimp, x)] <- 0
  out[is.na(out) & grepl(imp, x)] <- 1
  snow_unclassified(x, out, "water source"); out
}

# Toilet facility (hv205), improved type regardless of sharing (WS_TLET_H_IMP): flush/pour flush to sewer, septic
# tank, pit or unknown place, VIP, pit latrine with slab, composting/chemical toilet. Pit latrines without slab
# information (traditional, ordinary, rudimentary, log/rock floor, generic "latrine") are unimproved.
snow_sanitation <- function(x) {
  unimp <- paste0("without slab|no slab|open pit|hanging|bucket|potty|pan toilet|container|no facility|bush|field|outdoors|",
    "^river$|stream|somewhere else|elsewhere|ditch|open latrine|traditional|rudimentary|ordinary pit|^other$|^missing$|^99$|",
    "^latrine$|^no flush toilet$|without ventilation pipe|log/rock|without flush, don't know|no flush, don't know")
  imp <- paste0("sewer|septic|public system|flush to pit|flush - to pit|pour flush|^flush toilet|flush, don't know|",
    "flush - don't know|toilet to don't know|vip|ventilated|ventilation pipe|with slab|composting|ecosan|bio-digester|",
    "improved pit|chemical|with drainage|covered latrine|manual flush")
  out <- rep(NA_real_, length(x))
  out[grepl(unimp, x)] <- 0
  out[is.na(out) & grepl(imp, x)] <- 1
  snow_unclassified(x, out, "toilet facility"); out
}

snow_yesno <- function(x, what) {   # electricity (hv206), de facto (hv103)
  out <- ifelse(x == "yes", 1, ifelse(x %in% c("no", "missing", "9"), 0, NA_real_)); snow_unclassified(x, out, what); out
}
