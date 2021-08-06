import React, { useState } from 'react';
import {
  ExtendedNav,
  Header,
  Menu,
  NavDropDownButton, NavMenuButton,
  Search, Title
} from '@trussworks/react-uswds'
import { Link } from 'react-router-dom';
import { apiMap } from './Names'

export default function HeaderPanel() {
  const [ mobileNavOpen, setMobileNavOpen ] = useState(false)
  const [ navDropdownOpen, setNavDropdownOpen ] = useState([ false, false ])

  const handleToggleNavDropdown = index => {
    setNavDropdownOpen(prevNavDropdownOpen => {
      const newOpenState = Array(prevNavDropdownOpen.length).fill(false)

      newOpenState[index] = !prevNavDropdownOpen[index]
      return newOpenState
    })
  }

  const toggleMobileNav = () => {
    setMobileNavOpen(prevOpen => !prevOpen)
  }

  const handleSearch = () => { console.log('Search called') }

  const primaryNavItems = [
    <React.Fragment key="primaryNav_0">
      <NavDropDownButton
        menuId="extended-nav-section-one"
        isOpen={navDropdownOpen[0]}
        label="Random Names"
        onToggle={() => {
          handleToggleNavDropdown(0)
        }}
        isCurrent
      />
      <Menu
        id="extended-nav-section-one"
        items={
          Object.keys(apiMap).map(k =>
            <Link to={'/names/' + k}
                  onClick={() => handleToggleNavDropdown(0)}>
              {apiMap[k]}
            </Link>
          )
        }
        isOpen={navDropdownOpen[0]}
      />
    </React.Fragment>,
    <React.Fragment key="primaryNav_1">
      <NavDropDownButton
        menuId="extended-nav-section-two"
        isOpen={navDropdownOpen[1]}
        label="Section"
        onToggle={() => {
          handleToggleNavDropdown(1)
        }}
      />
      <Menu
        id="extended-nav-section-two"
        items={new Array(3).fill(<a href="#">Navigation link</a>)}
        isOpen={navDropdownOpen[1]}
      />
    </React.Fragment>,
    <a key="primaryNav_2" className="usa-nav__link">
      <span>Simple link</span>
    </a>
  ]

  const secondaryNavItems = [
    <a key="secondaryNav_0" href="">
      Secondary link
    </a>,
    <a key="secondaryNav_1" href="">
      Another secondary link
    </a>
  ]

  //     <GovBanner />
  return (<>
    <div className={`usa-overlay ${ mobileNavOpen ? 'is-visible' : '' }`}></div>
    <Header extended>
      <div className="usa-navbar">
        <Title id="extended-logo">
          <a href="/" title="Home" aria-label="Home">
            Hoop Demo
          </a>
        </Title>
        <NavMenuButton
          label="Menu"
          onClick={toggleMobileNav}
          className="usa-menu-btn"
        />
      </div>
      <ExtendedNav
        aria-label="Primary navigation"
        primaryItems={primaryNavItems}
        secondaryItems={secondaryNavItems}
        onToggleMobileNav={toggleMobileNav}
        mobileExpanded={mobileNavOpen}>
        <Search size="small" onSubmit={handleSearch} />
      </ExtendedNav>
    </Header>
  </>
  )
}
