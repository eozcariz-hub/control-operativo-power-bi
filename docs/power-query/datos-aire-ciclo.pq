let
    // =====================================================
    // ORIGEN: ZONA 6
    // =====================================================
    Origen = Z6_Origen,

    // Usar solo tablas internas
    SoloTablas = Table.SelectRows(
        Origen,
        each [Kind] = "Table"
    ),

    // Obtener tabla Sistema Aire
    TablaFiltrada = Table.SelectRows(
        SoloTablas,
        each [Name] = "Compresores_Aire"
    ),

    TablaBase =
        if Table.RowCount(TablaFiltrada) > 0 then
            TablaFiltrada{0}[Data]
        else
            #table({}, {}),

    // Limpiar espacios en nombres de columnas
    ColumnasLimpias = Table.TransformColumnNames(
        TablaBase,
        each Text.Trim(_)
    ),

    // Agregar Sistema
    AgregarSistema = Table.AddColumn(
        ColumnasLimpias,
        "Sistema",
        each "Sistema Aire",
        type text
    ),

    // Renombrar columnas al estándar
    RenombrarColumnas = Table.RenameColumns(
        AgregarSistema,
        {
            {"Día y Hora Local", "Fecha Local"},
            {"Nivel aceite", "Nivel de aceite"},
            {"Presión de descarga", "Presión descarga"}
        },
        MissingField.Ignore
    ),

    // Completar columnas faltantes con n/a
    CompletarColumnas =
        List.Accumulate(
            {
                "Sistema",
                "Equipo",
                "Fecha Local",
                "Nivel de aceite",
                "Presión descarga",
                "Horas de marcha",
                "Presión pulmón servicio",
                "Presión pulmón instrumento",
                "Punto Rocío Torre de Secado",
                "Novedades"
            },
            RenombrarColumnas,
            (Estado, Columna) =>
                if Table.HasColumns(Estado, Columna) then
                    Estado
                else
                    Table.AddColumn(
                        Estado,
                        Columna,
                        each "n/a",
                        type text
                    )
        ),

    // Orden final de columnas
    OrdenarColumnas = Table.SelectColumns(
        CompletarColumnas,
        {
            "Sistema",
            "Equipo",
            "Fecha Local",
            "Nivel de aceite",
            "Presión descarga",
            "Horas de marcha",
            "Presión pulmón servicio",
            "Presión pulmón instrumento",
            "Punto Rocío Torre de Secado",
            "Novedades"
        },
        MissingField.UseNull
    ),

    // Tipos de datos
    Tipos = Table.TransformColumnTypes(
        OrdenarColumnas,
        {
            {"Sistema", type text},
            {"Equipo", type text},
            {"Fecha Local", type date},
            {"Nivel de aceite", type text},
            {"Presión descarga", type text},
            {"Horas de marcha", type text},
            {"Presión pulmón servicio", type text},
            {"Presión pulmón instrumento", type text},
            {"Punto Rocío Torre de Secado", type text},
            {"Novedades", type text}
        }
    ),

    // Eliminar únicamente filas sin clave válida
    FiltrarValidos = Table.SelectRows(
        Tipos,
        each
            [Fecha Local] <> null
            and [Equipo] <> null
            and Text.Trim(Text.From([Equipo])) <> ""
    ),

    // Fijar el orden actual
    TablaBuffer = Table.Buffer(
        FiltrarValidos
    ),

    // Conservar una sola fila por equipo y día
    UnRegistroPorEquipoDia = Table.Distinct(
        TablaBuffer,
        {
            "Equipo",
            "Fecha Local"
        }
    )
in
    UnRegistroPorEquipoDia
