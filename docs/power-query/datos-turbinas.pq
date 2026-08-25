let
    Z1_Turbinas_Datos =
        Table.RenameColumns(
            Table.SelectColumns(
                Z1_Turbinas,
                {
                    "Fecha Local",
                    "Equipo",
                    "Nivel de aceite",
                    "Estado panel contra incendio",
                    "Filtro de aceite en servicio"
                }
            ),
            {
                {"Estado panel contra incendio", "Panel Contra Incendio"},
                {"Filtro de aceite en servicio", "Filtro de Aceite"}
            }
        ),

    Z1CD_Turbinas_Datos =
        Table.RenameColumns(
            Table.SelectColumns(
                Z1CD_Turbinas,
                {
                    "Fecha Local",
                    "Equipo",
                    "Nivel de aceite",
                    "Estado panel contra incendio",
                    "Filtro de aceite en servicio"
                }
            ),
            {
                {"Estado panel contra incendio", "Panel Contra Incendio"},
                {"Filtro de aceite en servicio", "Filtro de Aceite"}
            }
        ),

    Z2_Tg15_Datos =
        Table.ReorderColumns(
            Table.AddColumn(
                Table.RenameColumns(
                    Table.SelectColumns(
                        Z2_Tg15,
                        {
                            "Fecha Local",
                            "Nivel de Aceite ",
                            "Panel Contra Incendios",
                            "Filtro de Aceite "
                        }
                    ),
                    {
                        {"Nivel de Aceite ", "Nivel de aceite"},
                        {"Panel Contra Incendios", "Panel Contra Incendio"},
                        {"Filtro de Aceite ", "Filtro de Aceite"}
                    }
                ),
                "Equipo",
                each "TG15",
                type text
            ),
            {
                "Fecha Local",
                "Equipo",
                "Nivel de aceite",
                "Panel Contra Incendio",
                "Filtro de Aceite"
            }
        ),

    Z2_Turbinas_Datos =
        Table.AddColumn(
            Table.RenameColumns(
                Table.SelectColumns(
                    Z2_Turbinas,
                    {
                        "Fecha Local",
                        "Equipo",
                        "Nivel de aceite ",
                        "Estado Panel Contra Incendio"
                    }
                ),
                {
                    {"Nivel de aceite ", "Nivel de aceite"},
                    {"Estado Panel Contra Incendio", "Panel Contra Incendio"}
                }
            ),
            "Filtro de Aceite",
            each "N/A",
            type text
        ),

    Z4_TM2500_Datos =
        Table.AddColumn(
            Table.RenameColumns(
                Table.SelectColumns(
                    Z4_TM2500,
                    {
                        "Fecha Local",
                        "Equipo",
                        "% Aceite Turbina",
                        "Estado panel fuego y gas "
                    }
                ),
                {
                    {"% Aceite Turbina", "Nivel de aceite"},
                    {"Estado panel fuego y gas ", "Panel Contra Incendio"}
                }
            ),
            "Filtro de Aceite",
            each "N/A",
            type text
        ),

    Z4_Turbinas_Datos =
        Table.AddColumn(
            Table.RenameColumns(
                Table.SelectColumns(
                    Z4_Turbinas,
                    {
                        "Fecha Local",
                        "Equipo",
                        "Nivel de aceite ",
                        "Estado Panel Contra Incendio"
                    }
                ),
                {
                    {"Nivel de aceite ", "Nivel de aceite"},
                    {"Estado Panel Contra Incendio", "Panel Contra Incendio"}
                }
            ),
            "Filtro de Aceite",
            each "N/A",
            type text
        ),

    TablaConsolidada =
        Table.Combine(
            {
                Z1_Turbinas_Datos,
                Z1CD_Turbinas_Datos,
                Z2_Tg15_Datos,
                Z2_Turbinas_Datos,
                Z4_TM2500_Datos,
                Z4_Turbinas_Datos
            }
        ),

    TiposCorregidos =
        Table.TransformColumnTypes(
            TablaConsolidada,
            {
                {"Fecha Local", type date},
                {"Equipo", type text},
                {"Nivel de aceite", type text},
                {"Panel Contra Incendio", type text},
                {"Filtro de Aceite", type text}
            }
        ),

    EquipoNormalizado =
        Table.TransformColumns(
            TiposCorregidos,
            {
                {
                    "Equipo",
                    each
                        if _ = null then
                            null
                        else
                            let
                                EquipoOriginal = Text.Trim(_),
                                EquipoMayuscula = Text.Upper(EquipoOriginal),

                                Resto =
                                    if Text.StartsWith(EquipoMayuscula, "TG") then
                                        Text.Trim(Text.Range(EquipoOriginal, 2))
                                    else
                                        null,

                                EsTG =
                                    Resto <> null
                                    and
                                    (
                                        try Number.FromText(Resto)
                                        otherwise null
                                    ) <> null
                            in
                                if EsTG then
                                    "TG" & Resto
                                else
                                    EquipoOriginal,
                    type text
                }
            }
        ),

    DatosUnicos =
        Table.Distinct(
            EquipoNormalizado,
            {"Fecha Local", "Equipo"}
        )

in
    DatosUnicos
