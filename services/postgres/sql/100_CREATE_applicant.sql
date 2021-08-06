CREATE TABLE IF NOT EXISTS public.applicant (
    id BIGSERIAL,
    family_name character varying(255) not null,
    given_name character varying(255) not null,
    middle_name character varying(255) not null,
    date_of_birth date,
    country_of_birth character varying(255) not null
);
