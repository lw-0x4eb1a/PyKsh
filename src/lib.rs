use pyo3::prelude::*;
use pyo3::exceptions::PyRuntimeError;
mod uniform;

#[pyfunction]
fn iter_uniforms(src: &str) -> PyResult<Vec<uniform::UniformVarInfo>> {
    match uniform::iter_uniforms(src) {
        Ok(uniforms) => Ok(uniforms),
        Err(e) => Err(PyErr::new::<PyRuntimeError, _>(e)),
    }
}

#[pymodule]
fn pyksh(m: &Bound<'_, PyModule>) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(iter_uniforms, m)?)?;
    m.add_function(wrap_pyfunction!(uniform::make_uniform_var, m)?)?;
    Ok(())
}
