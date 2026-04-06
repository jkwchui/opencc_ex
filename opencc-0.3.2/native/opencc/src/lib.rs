use ferrous_opencc::config::BuiltinConfig;
use ferrous_opencc::OpenCC;
use rustler::{Atom, Env, Error, NifResult, ResourceArc};
use std::sync::Mutex;

mod atoms {
    rustler::atoms! {
        ok,
        error,
    }
}

// The Resource we will securely pass back to Elixir
pub struct OpenCCResource {
    pub instance: Mutex<OpenCC>,
}

#[allow(non_local_definitions)]
pub fn load(env: Env, _info: rustler::Term) -> bool {
    // Prefix with `let _ =` to explicitly ignore the unused return value
    let _ = rustler::resource!(OpenCCResource, env);
    true
}

#[rustler::nif]
fn new_builtin(config: String) -> NifResult<(Atom, ResourceArc<OpenCCResource>)> {
    let builtin_config = match config.as_str() {
        "s2t" => BuiltinConfig::S2t,
        "t2s" => BuiltinConfig::T2s,
        "s2tw" => BuiltinConfig::S2tw,
        "tw2s" => BuiltinConfig::Tw2s,
        "s2hk" => BuiltinConfig::S2hk,
        "hk2s" => BuiltinConfig::Hk2s,
        "s2twp" => BuiltinConfig::S2twp,
        "tw2sp" => BuiltinConfig::Tw2sp,
        "t2tw" => BuiltinConfig::T2tw,
        "tw2t" => BuiltinConfig::Tw2t,
        "t2hk" => BuiltinConfig::T2hk,
        "hk2t" => BuiltinConfig::Hk2t,
        _ => return Err(Error::Term(Box::new("invalid_builtin_config"))),
    };

    match OpenCC::from_config(builtin_config) {
        Ok(instance) => Ok((
            atoms::ok(),
            ResourceArc::new(OpenCCResource {
                instance: Mutex::new(instance),
            }),
        )),
        Err(e) => Err(Error::Term(Box::new(e.to_string()))),
    }
}

#[rustler::nif]
fn new_custom(path: String) -> NifResult<(Atom, ResourceArc<OpenCCResource>)> {
    match OpenCC::new(&path) {
        Ok(instance) => Ok((
            atoms::ok(),
            ResourceArc::new(OpenCCResource {
                instance: Mutex::new(instance),
            }),
        )),
        Err(e) => Err(Error::Term(Box::new(e.to_string()))),
    }
}

#[rustler::nif]
fn convert(resource: ResourceArc<OpenCCResource>, text: String) -> NifResult<(Atom, String)> {
    let instance = resource.instance.lock().unwrap();
    // convert() consumes the text reference and returns a new mapped String
    let converted = instance.convert(&text);
    Ok((atoms::ok(), converted))
}

rustler::init!("Elixir.OpenCC.Native", load = load);
