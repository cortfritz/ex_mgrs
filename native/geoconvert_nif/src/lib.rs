use rustler::{Atom, NifResult};
use geoconvert::{LatLon, Mgrs};

mod atoms {
    rustler::atoms! {
        ok,
        error,
    }
}

#[rustler::nif]
fn latlon_to_mgrs_nif(lat: f64, lon: f64, precision: i32) -> NifResult<(Atom, String)> {
    match LatLon::create(lat, lon) {
        Ok(coord) => {
            let mgrs = coord.to_mgrs(precision);
            Ok((atoms::ok(), mgrs.to_string()))
        }
        Err(e) => Ok((atoms::error(), format!("Invalid coordinates: {}", e))),
    }
}

#[rustler::nif]
fn mgrs_to_latlon_nif(mgrs: String) -> NifResult<(Atom, (f64, f64))> {
    match Mgrs::parse_str(&mgrs) {
        Ok(mgrs_coord) => {
            let latlon = mgrs_coord.to_latlon();
            Ok((atoms::ok(), (latlon.latitude(), latlon.longitude())))
        }
        Err(_e) => Ok((atoms::error(), (0.0, 0.0))),
    }
}

rustler::init!("Elixir.ExMgrs.Native");