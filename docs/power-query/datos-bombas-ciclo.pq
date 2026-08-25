let
    // =====================================================
    // ORIGEN
    // =====================================================
    Zona5 = Datos_Bombas_Z5,
    Zona6 = Datos_Bombas_Z6,

    Consolidado = Table.Combine(
        {
            Zona5,
            Zona6
        }
    ),

    // =====================================================
    // ASEGURAR COLUMNAS NECESARIAS
    // =====================================================
    ColumnasEsperadas = {
        "Fecha Local",
        "Sistema",
        "Equipo",
        "Nivel de aceite",
        "Presión succión",
        "Presión descarga",
        "Temperatura",
        "Novedades"
    },

    CompletarColumnas =
        List.Accumulate(
            ColumnasEsperadas,
            Consolidado,
            (Estado, Columna) =>
                if Table.HasColumns(Estado, Columna) then
                    Estado
                else if Columna = "Fecha Local" then
                    Table.AddColumn(
                        Estado,
                        Columna,
                        each null,
                        type nullable date
                    )
                else
                    Table.AddColumn(
                        Estado,
                        Columna,
                        each null
                    )
        ),

    // =====================================================
    // REEMPLAZAR ERRORES EXISTENTES POR NULL
    // =====================================================
    ReemplazarErrores = Table.ReplaceErrorValues(
        CompletarColumnas,
        {
            {"Fecha Local", null},
            {"Sistema", null},
            {"Equipo", null},
            {"Nivel de aceite", null},
            {"Presión succión", null},
            {"Presión descarga", null},
            {"Temperatura", null},
            {"Novedades", null}
        }
    ),

    // =====================================================
    // NORMALIZAR FECHA
    // =====================================================
    ConvertirFecha = Table.TransformColumns(
        ReemplazarErrores,
        {
            {
                "Fecha Local",
                each try Date.From(_) otherwise null,
                type nullable date
            }
        }
    ),

    // =====================================================
    // LIMPIAR SISTEMA Y EQUIPO
    // =====================================================
    LimpiarClaves = Table.TransformColumns(
        ConvertirFecha,
        {
            {
                "Sistema",
                each
                    if _ = null then
                        null
                    else
                        Text.Trim(
                            Text.Clean(
                                Text.Replace(
                                    Text.From(_),
                                    Character.FromNumber(160),
                                    " "
                                )
                            )
                        ),
                type nullable text
            },
            {
                "Equipo",
                each
                    if _ = null then
                        null
                    else
                        Text.Upper(
                            Text.Trim(
                                Text.Clean(
                                    Text.Replace(
                                        Text.From(_),
                                        Character.FromNumber(160),
                                        " "
                                    )
                                )
                            )
                        ),
                type nullable text
            }
        }
    ),

    // =====================================================
    // FILTRAR SOLO FILAS REALES
    // NO SE CREAN FILAS PARA EQUIPOS SIN REGISTRO
    // =====================================================
    FiltrarValidos = Table.SelectRows(
        LimpiarClaves,
        each
            [Fecha Local] <> null
            and [Sistema] <> null
            and [Sistema] <> ""
            and [Equipo] <> null
            and [Equipo] <> ""
    ),

    // =====================================================
    // AGREGAR ÍNDICE
    // =====================================================
    AgregarIndice = Table.AddIndexColumn(
        FiltrarValidos,
        "Índice",
        1,
        1,
        Int64.Type
    ),

    // =====================================================
    // UN SOLO REGISTRO POR SISTEMA + EQUIPO + FECHA
    // =====================================================
    AgruparEquipoDia = Table.Group(
        AgregarIndice,
        {
            "Sistema",
            "Equipo",
            "Fecha Local"
        },
        {
            {
                "Registro",
                each
                    Table.First(
                        Table.Sort(
                            _,
                            {
                                {"Índice", Order.Ascending}
                            }
                        )
                    ),
                type record
            }
        }
    ),

    // =====================================================
    // EXPANDIR REGISTRO CONSERVADO
    // =====================================================
    ExpandirRegistro = Table.ExpandRecordColumn(
        AgruparEquipoDia,
        "Registro",
        {
            "Nivel de aceite",
            "Presión succión",
            "Presión descarga",
            "Temperatura",
            "Novedades"
        },
        {
            "Nivel de aceite",
            "Presión succión",
            "Presión descarga",
            "Temperatura",
            "Novedades"
        }
    ),

    // =====================================================
    // FUNCIÓN DE NORMALIZACIÓN
    // n/a, N/A, na, null y vacío = "-"
    // 0 SE CONSERVA COMO 0
    // =====================================================
    NormalizarValor = (Valor as any) as text =>
        let
            ValorSeguro =
                try Valor
                otherwise null,

            Texto =
                if ValorSeguro = null then
                    ""
                else
                    Text.Trim(Text.From(ValorSeguro)),

            TextoMinuscula =
                Text.Lower(Texto),

            Resultado =
                if Texto = ""
                    or TextoMinuscula = "n/a"
                    or TextoMinuscula = "na"
                then
                    "-"
                else
                    Texto
        in
            Resultado,

    // =====================================================
    // NORMALIZAR CAMPOS OPERATIVOS
    // =====================================================
    NormalizarCampos = Table.TransformColumns(
        ExpandirRegistro,
        {
            {
                "Nivel de aceite",
                each NormalizarValor(_),
                type text
            },
            {
                "Presión succión",
                each NormalizarValor(_),
                type text
            },
            {
                "Presión descarga",
                each NormalizarValor(_),
                type text
            },
            {
                "Temperatura",
                each NormalizarValor(_),
                type text
            },
            {
                "Novedades",
                each NormalizarValor(_),
                type text
            }
        }
    ),

    // =====================================================
    // SELECCIONAR COLUMNAS
    // =====================================================
    SeleccionarColumnas = Table.SelectColumns(
        NormalizarCampos,
        {
            "Sistema",
            "Equipo",
            "Fecha Local",
            "Nivel de aceite",
            "Presión succión",
            "Presión descarga",
            "Temperatura",
            "Novedades"
        },
        MissingField.UseNull
    ),

    // =====================================================
    // TIPOS FINALES
    // =====================================================
    TiposFinales = Table.TransformColumnTypes(
        SeleccionarColumnas,
        {
            {"Sistema", type text},
            {"Equipo", type text},
            {"Fecha Local", type date},
            {"Nivel de aceite", type text},
            {"Presión succión", type text},
            {"Presión descarga", type text},
            {"Temperatura", type text},
            {"Novedades", type text}
        },
        "es-AR"
    ),

    // =====================================================
    // ORDEN FINAL
    // =====================================================
    OrdenarFilas = Table.Sort(
        TiposFinales,
        {
            {"Fecha Local", Order.Descending},
            {"Sistema", Order.Ascending},
            {"Equipo", Order.Ascending}
        }
    )

in
    OrdenarFilas
