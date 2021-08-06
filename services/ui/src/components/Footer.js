import React from 'react';
import {
  Address, Footer, FooterNav, Grid, GridContainer, Logo, SocialLinks
} from '@trussworks/react-uswds'

export default function FooterPanel() {
  const returnToTop = (
    <GridContainer className="usa-footer__return-to-top">
      <a href="#">Return to top</a>
    </GridContainer>
  )

  const footerPrimary = (
    <FooterNav
      aria-label="Footer navigation"
      size="medium"
      links={Array(5).fill(
        <a className="usa-footer__primary-link">
          Primary link
        </a>
      )}
    />
  )

  const footerSecondary = (
    <>
      <Grid row gap>
        <Logo
          medium
          heading={<h3 className="usa-footer__logo-heading">
            U.S. Citizenship and Immigration Services</h3>
          }
        />
        <Grid className="usa-footer__contact-links" mobileLg={{ col: 6 }}>
          <SocialLinks
            links={[
              <a
                key="facebook"
                className="usa-social-link usa-social-link--facebook">
                <span>Facebook</span>
              </a>,
              <a
                key="twitter"
                className="usa-social-link usa-social-link--twitter">
                <span>Twitter</span>
              </a>,
              <a
                key="youtube"
                className="usa-social-link usa-social-link--youtube">
                <span>YouTube</span>
              </a>,
              <a
                key="rss"
                className="usa-social-link usa-social-link--rss">
                <span>RSS</span>
              </a>
            ]}
          />
          <h3 className="usa-footer__contact-heading">Agency Contact Center</h3>
          <Address
            medium
            items={[
              <a key="telephone" href="tel:1-800-555-5555">
                (800) CALL-GOVT
              </a>,
              <a key="email" href="mailto:info@agency.gov">
                info@agency.gov
              </a>
            ]}
          />
        </Grid>
      </Grid>
    </>
  )

  return <Footer
      returnToTop={returnToTop}
      primary={footerPrimary}
      secondary={footerSecondary}
  />
}
