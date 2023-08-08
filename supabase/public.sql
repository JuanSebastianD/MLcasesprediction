create table if not exists ref_urban_growth_boundary
(
    region    text,
    growth_id uuid,
    geom      geometry (Geometry, 7844)
);

alter table ref_urban_growth_boundary
    owner to postgres;

create index ref_urban_growth_geom_idx
    on ref_urban_growth_boundary using gist (geom);

grant select on ref_urban_growth_boundary to geoserver;


create or replace function check_dcp_admin(OUT isAdmin boolean) AS $$
BEGIN
    SELECT EXISTS(SELECT * FROM public.profiles WHERE id = auth.uid() AND is_admin) into isAdmin;
END;
$$ LANGUAGE plpgsql;

create or replace function check_dcp_edit(IN planId uuid, OUT canEdit boolean) AS $$
BEGIN
    SELECT EXISTS(
        SELECT *
        FROM dcp_user_permission
        WHERE can_update AND user_id = auth.uid() AND plan_id = planId
    ) into canEdit;
END;
$$ LANGUAGE plpgsql;

create or replace function check_dcp_view(IN planId uuid, OUT canView boolean) AS $$
BEGIN
    SELECT EXISTS(
        SELECT plan_id
        FROM dcp_user_permission
        WHERE user_id = auth.uid() AND plan_id = planId
        UNION ALL
        SELECT plan_id
        FROM development_contribution_plan
        WHERE plan_id = planId AND is_public is true
    ) into canView;
END;
$$ LANGUAGE plpgsql;

create or replace function check_dcp_owner(IN planId uuid, OUT isOwner boolean) AS $$
BEGIN
    SELECT EXISTS(
        SELECT *
        FROM development_contribution_plan
        WHERE owner_id = auth.uid() AND plan_id = planId
    ) into isOwner;
END;
$$ LANGUAGE plpgsql;