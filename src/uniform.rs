use glsl::parser::Parse;
use glsl::syntax::*;
use glsl::visitor::{Visit, Visitor, Host};
use std::collections::HashSet;
use std::hash::{DefaultHasher, Hash, Hasher};
use std::fmt::Display;
use pyo3::prelude::*;

#[derive(Clone, Debug, Default, PartialEq)]
#[pyclass]
pub(crate) struct UniformVarInfo {
    #[pyo3(get)]
    pub name: String,

    #[pyo3(get)]
    pub type_specifier: String,

    #[pyo3(get)]
    pub n: usize,
}

#[pyfunction]
pub(crate)fn make_uniform_var(name: &str, type_specifier: &str, n: usize) -> UniformVarInfo {
    UniformVarInfo {
        name: name.to_owned(),
        type_specifier: type_specifier.to_owned(),
        n,
    }
}

#[pymethods]
impl UniformVarInfo {
    fn display(&self) -> String {
        if self.n == 1 {
            format!("{} {}", self.type_specifier, self.name)
        }
        else {
            format!("{} {}[{}]", self.type_specifier, self.name, self.n)
        }
    }

    #[getter]
    fn id(&self) -> usize {
        match self.type_specifier.as_str() {
            "Float"=> 0,
            "Vec2"=> 2,
            "Vec3"=> 3,
            "Vec4"=> 4,
            "Mat4"=> 20,
            "Sampler2D"=> 43,
            _=> unreachable!(),
        }
    }

    #[getter]
    fn num_bits(&self) -> usize {
        match self.type_specifier.as_str() {
            "Float"=> 4,
            "Vec2"=> 8,
            "Vec3"=> 12,
            "Vec4"=> 16,
            "Mat4"=> 64,
            "Sampler2D"=> 0,
            _=> unreachable!(),
        }
    }

    #[getter]
    fn is_sampler_2d(&self) -> bool {
        self.type_specifier == "Sampler2D"
    }

    fn __repr__(&self) -> String {
        format!("<UniformVar ({})>", self.display())
    }

    fn __str__(&self) -> String {
        self.__repr__()
    }

    fn __eq__(&self, other: &UniformVarInfo) -> bool {
        self.name == other.name
    }

    fn __hash__(&self) -> u64 {
        let mut hasher = DefaultHasher::new();
        self.name.hash(&mut hasher);
        self.type_specifier.hash(&mut hasher);
        self.n.hash(&mut hasher);
        hasher.finish()
    }
}

impl Display for &UniformVarInfo {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        if self.n == 1 {
            write!(f, "{} {}", self.type_specifier, self.name)
        }
        else {
            write!(f, "{} {}[{}]", self.type_specifier, self.name, self.n)
        }
    }
}

#[derive(Clone, Debug, Default)]
struct ShaderInfo {
    pub declared_uniforms: Vec<UniformVarInfo>,
    pub visited_identifiers: HashSet<String>,
}

impl ShaderInfo {
    pub fn get_visited_uniforms(&self) -> Vec<UniformVarInfo> {
        self.declared_uniforms
            .iter()
            .filter(|u| self.visited_identifiers.contains(&u.name))
            .cloned()
            .collect()
    }
}

impl Visitor for ShaderInfo {
    fn visit_single_declaration(&mut self, declaration: &SingleDeclaration) -> Visit {
        /*
        called for any var declaration, including top-level uniforms and const,
        but not for block defs
        */
        let is_uniform = match declaration.ty.qualifier {
            Some(ref q)=> {
                let NonEmpty(ref s) = q.qualifiers;
                matches!(s[0], TypeQualifierSpec::Storage(StorageQualifier::Uniform))
            }
            None=> false,
        };

        if !is_uniform {
            // only collect uniform vars
            return Visit::Parent;
        }

        if declaration.name.is_some() {
            let name = declaration.name.as_ref().unwrap().as_str().to_owned();
            let type_specifier = declaration.ty.ty.ty.clone();
            let n = if declaration.array_specifier.is_some() {
                // I think GLSL can only have 1D array vars...
                let spec_dim = &declaration.array_specifier.as_ref().unwrap().dimensions.0[0];
                match spec_dim {
                    ArraySpecifierDimension::ExplicitlySized(value) => 
                    match **value {
                        Expr::IntConst(n) => n as usize,
                        Expr::UIntConst(n) => n as usize,
                        _ => 1, // I think only int consts are possible for array dims
                    },
                    ArraySpecifierDimension::Unsized => 1,
                }
            }
            else {
                1
            };

            self.declared_uniforms.push(UniformVarInfo {
                name,
                type_specifier: format!("{:?}", type_specifier),
                n,
            });
        }
        Visit::Parent
    }

    fn visit_identifier(&mut self, identifier: &Identifier) -> Visit {
        let name = identifier.0.clone();
        self.visited_identifiers.insert(name);
        Visit::Children
    }

    fn visit_statement(&mut self, statement: &Statement) -> Visit {
        match statement {
            Statement::Simple(state)=> {
                if let SimpleStatement::Declaration(
                    Declaration::InitDeclaratorList(list)) = state.as_ref() {
                    if let Some(ref init) = list.head.initializer {
                        // I don't known why this vistor is needed...
                        init.visit(self);
                    }
                }
            },
            Statement::Compound(_state)=> {
                // println!("compound statement: {:#?}", state);
            },
        }
        Visit::Children
    }
}

pub(crate) fn iter_uniforms(src: &str) -> Result<Vec<UniformVarInfo>, String> {
    let shader = ShaderStage::parse(src).map_err(|e| format!("Failed to parse AST: {}", e))?;
    let mut info = ShaderInfo::default();
    shader.visit(&mut info);
    Ok(info.get_visited_uniforms().to_vec())
}